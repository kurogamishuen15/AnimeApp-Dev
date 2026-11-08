#!/usr/bin/env python3
"""Ejecutor IA aislado. No instala imágenes ni inicia servicios persistentes."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import selectors
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import uuid

STDOUT_LIMIT = 1024 * 1024
STDERR_LIMIT = 64 * 1024
FILE_LIMIT = 4 * 1024 * 1024
CORPUS_LIMIT = 64 * 1024 * 1024


class Blocked(Exception):
    """Una precondición de seguridad no se satisface."""


def command(argv, *, timeout=30, cwd=None, input=None):
    """Leer ambas tuberías incrementalmente; cortar antes de agotar RAM host."""
    with tempfile.TemporaryFile() as stdin, selectors.DefaultSelector() as selector:
        if input is not None:
            payload = input.encode('utf-8')
            if len(payload) > 64 * 1024:
                raise Blocked('Entrada de proceso excede presupuesto de 64 KiB')
            stdin.write(payload)
            stdin.seek(0)
        process = subprocess.Popen(argv, cwd=cwd, stdin=stdin,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   start_new_session=True)
        buffers = {'stdout': bytearray(), 'stderr': bytearray()}
        limits = {'stdout': STDOUT_LIMIT, 'stderr': STDERR_LIMIT}
        deadline = time.monotonic() + timeout
        for name in buffers:
            selector.register(getattr(process, name), selectors.EVENT_READ, name)
        try:
            while selector.get_map():
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise subprocess.TimeoutExpired(argv[0], timeout)
                for key, _ in selector.select(min(remaining, 0.2)):
                    data = os.read(key.fileobj.fileno(), 8192)
                    if not data:
                        selector.unregister(key.fileobj)
                        continue
                    buffer = buffers[key.data]
                    if len(buffer) + len(data) > limits[key.data]:
                        raise Blocked('Salida de proceso excede presupuesto; no se acepta JSON truncado')
                    buffer.extend(data)
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired(argv[0], timeout)
            code = process.wait(timeout=remaining)
        finally:
            # Matar también descendientes que mantengan las tuberías abiertas.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
            process.stdout.close()
            process.stderr.close()
        return subprocess.CompletedProcess(argv, code,
                                          buffers['stdout'].decode('utf-8', errors='replace'),
                                          buffers['stderr'].decode('utf-8', errors='replace'))


def git(root, *args):
    result = command(['git', '-C', str(root), *args])
    if result.returncode:
        raise Blocked('No se pudo comprobar el repositorio Git: ' + ' '.join(args[:2]))
    return result.stdout


def load_mission(path):
    try:
        with Path(path).open('rb') as stream:
            payload = stream.read(128 * 1024 + 1)
        if len(payload) > 128 * 1024:
            raise Blocked('Misión excede presupuesto de 128 KiB')
        mission = json.loads(payload)
    except (OSError, ValueError) as exc:
        raise Blocked('Misión JSON ilegible o inválida') from exc
    if not isinstance(mission, dict):
        raise Blocked('La misión debe ser un objeto JSON')
    objective = mission.get('objective')
    if not isinstance(objective, str) or not objective.strip() or len(objective.encode()) > 32768:
        raise Blocked('objective debe ser texto no vacío de máximo 32 KiB')
    paths = mission.get('allowed_paths')
    if not isinstance(paths, list) or not paths:
        raise Blocked('allowed_paths requiere archivos relativos exactos')
    context = mission.get('context_paths', [])
    if not isinstance(context, list) or len(context) > 1024 or len(paths) > 16:
        raise Blocked('Máximo 16 allowed_paths y 1024 context_paths explícitos')
    for value in paths + context:
        if not isinstance(value, str):
            raise Blocked('Ruta no textual en allowed_paths')
        p = PurePosixPath(value)
        if (not value or p.is_absolute() or str(p) != value or
                any(part in ('.', '..', '.git', '.ai-local') for part in p.parts)
                or any(c in value for c in '*?[]:\\\x00\n\r')):
            raise Blocked('Ruta no permitida: ' + repr(value))
        if sensitive_path(value):
            raise Blocked('Ruta potencialmente sensible excluida del contexto: ' + repr(value))
    if len(paths) != len(set(paths)):
        raise Blocked('allowed_paths contiene duplicados')
    mission['context_paths'] = context
    for key, default, upper in [('timeout_seconds', 900, 3600), ('max_attempts', 1, 3)]:
        value = mission.get(key, default)
        if type(value) is not int or not 1 <= value <= upper:
            raise Blocked(f'{key} debe estar entre 1 y {upper}')
        mission[key] = value
    validations = mission.get('validation_commands', [])
    if not isinstance(validations, list) or any(
        not isinstance(v, list) or not v or any(not isinstance(a, str) or not a or '\x00' in a for a in v)
        for v in validations
    ):
        raise Blocked('validation_commands debe contener listas argv no vacías')
    mission['validation_commands'] = validations
    if mission.get('network', 'none') not in ('none', 'bridge'):
        raise Blocked('network solo admite none o bridge explícito')
    if mission.get('commit', False) is not False:
        raise Blocked('commit automático no implementado; revisar y confirmar manualmente')
    image = mission.get('image')
    if image is not None and (not isinstance(image, str) or not image or image.startswith('-')):
        raise Blocked('image inválida')
    return mission


def sensitive_path(value):
    for part in PurePosixPath(value).parts:
        part = part.lower()
        if (part.startswith('.env') or part in ('.ssh', '.aws', '.codex', '.gnupg') or
                part.endswith(('.pem', '.key', '.p12', '.pfx', '.keystore')) or
                re.search(r'(^|[._-])(auth|secrets?|credentials?|tokens?|keys?)([._-]|$)', part)):
            return True
    return False


def checked_path(root, relative):
    current = root
    for component in PurePosixPath(relative).parts:
        current = current / component
        if current.is_symlink():
            raise Blocked('No se permiten enlaces simbólicos: ' + relative)
    if current.exists() and not current.is_file():
        raise Blocked('Solo se permiten archivos exactos: ' + relative)
    return current


def inspect_repository(root, mission):
    root = Path(root).resolve(strict=True)
    if Path(git(root, 'rev-parse', '--show-toplevel').strip()).resolve() != root:
        raise Blocked('--root debe ser la raíz exacta del repositorio')
    if git(root, 'diff', '--cached', '--name-only').strip():
        raise Blocked('Hay cambios staged previos; no se ejecutará la misión')
    tracked = git(root, 'ls-files', '-z').split('\x00')
    tracked = [p for p in tracked if p]
    requested = set(mission['allowed_paths'] + mission.get('context_paths', []))
    budget = 0
    for p in requested:
        if sensitive_path(p):
            raise Blocked('Contexto sensible bloqueado')
        checked_path(root, p)
        source = root / p
        if p not in tracked or not source.is_file():
            raise Blocked('run admite solo archivos existentes tracked: ' + p)
        size = source.stat().st_size
        if size > FILE_LIMIT:
            raise Blocked('Archivo de contexto excede 4 MiB: ' + p)
        budget += size
    if budget > CORPUS_LIMIT:
        raise Blocked('Contexto excede presupuesto total de 64 MiB')
    if git(root, 'diff', '--name-only').strip():
        raise Blocked('Hay cambios tracked locales; guardarlos antes de ejecutar')
    for p in mission['allowed_paths']:
        if (root / p).exists() and p not in tracked:
            raise Blocked('No se sobrescribe archivo untracked: ' + p)
    return root, sorted(requested)


def codex_capabilities():
    if not shutil.which('codex'):
        raise Blocked('Codex CLI no está en PATH')
    general = command(['codex', '--help'])
    execute = command(['codex', 'exec', '--help'])
    if general.returncode or execute.returncode:
        raise Blocked('No se pudo auditar la ayuda de Codex instalado')
    for flag in ('--ask-for-approval',):
        if flag not in general.stdout:
            raise Blocked('Codex carece de ' + flag)
    for flag in ('--json', '--ephemeral', '--sandbox'):
        if flag not in execute.stdout:
            raise Blocked('Codex exec carece de ' + flag)
    return command(['codex', '--version']).stdout.strip()


def container_preflight(mission):
    if not shutil.which('podman'):
        raise Blocked('Podman no está en PATH; no hay fallback al host')
    result = command(['podman', 'info', '--format', 'json'])
    try:
        info = json.loads(result.stdout)
        rootless = info['host']['security']['rootless'] is True
    except (ValueError, KeyError, TypeError):
        rootless = False
    if result.returncode or not rootless:
        raise Blocked('Podman rootless no comprobado; no hay fallback al host')
    image = mission.get('image')
    if not image:
        raise Blocked('Falta image local preaprovisionada; no se descargan imágenes')
    result = command(['podman', 'image', 'inspect', '--format',
                      '{{.Id}}\n{{json .Config.Labels}}', image])
    try:
        image_id, label_json = result.stdout.strip().split('\n', 1)
        labels = json.loads(label_json) or {}
        if not isinstance(labels, dict):
            raise ValueError('Labels inválidas')
    except (ValueError, KeyError, TypeError, IndexError):
        raise Blocked('Imagen local no comprobada')
    if result.returncode or not isinstance(image_id, str) or not image_id.startswith('sha256:'):
        raise Blocked('Imagen local no comprobada')
    if labels.get('io.animeapp.ai.auth-mode') != 'external-broker':
        raise Blocked('Imagen sin contrato external-broker; no montar ni hornear credenciales')
    if mission.get('network', 'none') == 'none':
        raise Blocked('Red none: proveedor remoto inaccesible; declarar bridge solo con broker preparado')
    if mission.get('broker_prepared') is not True:
        raise Blocked('Se requiere broker_prepared:true tras preparar autenticación externa')
    return image_id


def container_argv(image, work, name, network='none', writable_paths=()):
    argv = ['podman', 'run', '--rm', '--pull=never', '--name', name,
            '--image-volume=ignore', '--log-driver=none', '--http-proxy=false',
            '--network', network, '--memory', '1g', '--memory-swap', '1g', '--cpus', '1',
            '--pids-limit', '128', '--cap-drop', 'all',
            '--security-opt', 'no-new-privileges', '--userns', 'keep-id',
            '--ulimit', f'fsize={FILE_LIMIT}:{FILE_LIMIT}',
            '--read-only', '--tmpfs', '/tmp:rw,nosuid,nodev,size=128m',
            '--env', 'HOME=/tmp/ai-home', '--workdir', '/workspace',
            '--volume', str(work) + ':/workspace:ro,Z']
    for relative in writable_paths:
        argv += ['--volume', str(Path(work) / relative) + ':/workspace/' + relative + ':rw,Z']
    return argv + ['--entrypoint', 'codex', image]


def parse_events(output):
    totals = {'input_tokens': None, 'output_tokens': None, 'cached_input_tokens': None,
              'tool_count': 0, 'invalid_json_lines': 0}
    for line in output.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            totals['invalid_json_lines'] += 1
            continue
        if not isinstance(event, dict):
            continue
        if event.get('type') == 'turn.completed':
            usage = event.get('usage')
            if isinstance(usage, dict):
                for key in ('input_tokens', 'output_tokens', 'cached_input_tokens'):
                    value = usage.get(key)
                    if type(value) is int and value >= 0:
                        totals[key] = (totals[key] or 0) + value
        item = event.get('item', {})
        if (event.get('type') == 'item.completed' and isinstance(item, dict)
                and item.get('type') in ('command_execution', 'mcp_tool_call', 'web_search')):
            totals['tool_count'] += 1
    return totals


def snapshot(root):
    result = {}
    for p in root.rglob('*'):
        if p.is_symlink():
            raise Blocked('El contenedor produjo un enlace simbólico')
        if p.is_file():
            result[p.relative_to(root).as_posix()] = file_hash(p)
        elif not p.is_dir():
            raise Blocked('El contenedor produjo un archivo especial')
    return result


def file_hash(path):
    digest = hashlib.sha256()
    total = 0
    with path.open('rb') as stream:
        while data := stream.read(64 * 1024):
            total += len(data)
            if total > FILE_LIMIT:
                raise Blocked('Archivo excede presupuesto de 4 MiB')
            digest.update(data)
    return digest.hexdigest()


def bounded_copy(source, destination):
    total = 0
    with source.open('rb') as src, destination.open('wb') as dest:
        while chunk := src.read(64 * 1024):
            total += len(chunk)
            if total > FILE_LIMIT:
                raise Blocked('Archivo creció sobre presupuesto durante copia')
            dest.write(chunk)
    shutil.copymode(source, destination)
    return total


def provider_probe(image, work, network, timeout):
    """Diagnóstico dentro de imagen; la autenticación final depende de exec real."""
    deadline = time.monotonic() + timeout
    def probe(arguments):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise Blocked('Tiempo del diagnóstico agotado')
        name = 'anime-doctor-' + uuid.uuid4().hex[:12]
        return run_container(container_argv(image, work, name, network) + arguments,
                             min(remaining, 30), name)
    for args, flags in ((['--help'], ('--ask-for-approval',)),
                        (['exec', '--help'], ('--json', '--ephemeral', '--sandbox', '--skip-git-repo-check')),
                        (['doctor', '--help'], ('--json', '--network-only'))):
        help_result = probe(args)
        if help_result.returncode or any(flag not in help_result.stdout for flag in flags):
            raise Blocked('Imagen sin capacidades Codex necesarias auditadas')
    result = probe(['doctor', '--json', '--network-only'])
    if result.returncode:
        raise Blocked('Diagnóstico del proveedor dentro de imagen fallido; no se ejecutará misión')
    try:
        value = json.loads(result.stdout)
    except ValueError:
        raise Blocked('Diagnóstico del proveedor sin JSON válido')
    if not isinstance(value, (dict, list)):
        raise Blocked('Diagnóstico del proveedor sin informe estructurado')


def run_container(argv, timeout, name, *, input=None):
    try:
        return command(argv, timeout=timeout, input=input)
    except subprocess.TimeoutExpired:
        raise Blocked('Tiempo máximo agotado; contenedor detenido')
    finally:
        # --rm no basta si el cliente muere por timeout.
        command(['podman', 'rm', '--force', name], timeout=15)


def execute(mission, root, tracked, image, report):
    local = root / '.ai-local'
    if local.is_symlink():
        raise Blocked('.ai-local no puede ser un enlace')
    local.mkdir(mode=0o700, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='autonomy-', dir=local) as folder:
        work = Path(folder)
        total = 0
        for relative in tracked:
            src = root / relative
            if src.exists():
                dest = work / relative
                dest.parent.mkdir(parents=True, exist_ok=True)
                total += bounded_copy(src, dest)
                if total > CORPUS_LIMIT:
                    raise Blocked('Copia de contexto excede 64 MiB')
        before = snapshot(work)
        prompt = ('Trabaja exclusivamente sobre estos archivos exactos: ' +
                  json.dumps(mission['allowed_paths'], ensure_ascii=False) +
                  '. No uses red ni leas secretos. Objetivo:\n' + mission['objective'])
        name = 'anime-ai-' + uuid.uuid4().hex[:12]
        base = container_argv(image, work, name, mission.get('network', 'none'),
                              mission['allowed_paths'])
        # La CLI auditada admite -a global y sandbox workspace-write en exec.
        argv = base + ['-a', 'never', 'exec', '--sandbox', 'workspace-write',
                       '--ephemeral', '--json', '--skip-git-repo-check', '-']
        started = time.monotonic()
        provider_probe(image, work, mission.get('network', 'none'), mission['timeout_seconds'])
        report['provider_probe'] = 'doctor_exit_zero; autenticación pendiente de exec real'
        remaining = mission['timeout_seconds'] - (time.monotonic() - started)
        if remaining <= 0:
            raise Blocked('Tiempo máximo consumido por diagnóstico')
        result = run_container(argv, remaining, name, input=prompt)
        report.update(parse_events(result.stdout))
        report['exit_code'] = result.returncode
        report['attempts'] = 1  # No reintentos automáticos sin evidencia de progreso.
        report['runtime_seconds'] = round(time.monotonic() - started, 3)
        if result.returncode:
            raise Blocked('Codex aislado falló; salida privada no persistida')
        events = [json.loads(line) for line in result.stdout.splitlines()
                  if line.strip()] if not report['invalid_json_lines'] else []
        if (report['invalid_json_lines'] or not any(
                isinstance(e, dict) and e.get('type') == 'turn.completed' for e in events)
                or any(isinstance(e, dict) and e.get('type') in ('turn.failed', 'error') for e in events)):
            raise Blocked('Codex no confirmó un turno completo mediante JSONL íntegro')
        if not mission['validation_commands']:
            raise Blocked('Sin validation_commands no se integran cambios automáticamente')
        for validation in mission['validation_commands']:
            remaining = mission['timeout_seconds'] - (time.monotonic() - started)
            if remaining <= 0:
                raise Blocked('Sin tiempo restante para validar')
            name = 'anime-check-' + uuid.uuid4().hex[:12]
            args = container_argv(image, work, name, 'none')
            pos = args.index('--entrypoint')
            args[pos + 1] = validation[0]
            check = run_container(args + validation[1:], remaining, name)
            report['validation_exit_codes'].append(check.returncode)
            if check.returncode:
                raise Blocked('Validación aislada fallida; no se aplican cambios')
        after = snapshot(work)
        changed = {p for p in before.keys() | after.keys() if before.get(p) != after.get(p)}
        if not changed <= set(mission['allowed_paths']):
            raise Blocked('Cambios fuera de allowlist; no se aplica ningún archivo')
        # Detectar cambios concurrentes antes de integrar; nunca sobrescribir trabajo ajeno.
        inspect_repository(root, mission)
        for p in tracked:
            source = root / p
            current = file_hash(source) if source.exists() else None
            if current != before.get(p):
                raise Blocked('Cambio concurrente detectado; integración cancelada')
        for p in sorted(changed):
            destination = checked_path(root, p)
            if p in after:
                destination.parent.mkdir(parents=True, exist_ok=True)
                bounded_copy(work / p, destination)
            elif destination.exists():
                destination.unlink()
        report['changed_paths'] = sorted(changed)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    sub.add_parser('doctor')
    for action in ('plan', 'run'):
        part = sub.add_parser(action)
        part.add_argument('--mission', required=True)
        part.add_argument('--root', required=True)
    args = parser.parse_args(argv)
    report = {'status': 'blocked', 'input_tokens': None, 'output_tokens': None,
              'cached_input_tokens': None, 'tool_count': 0, 'attempts': 0,
              'validation_exit_codes': [], 'changed_paths': []}
    root = None
    started = time.monotonic()
    try:
        report['codex_version'] = codex_capabilities()
        if args.action == 'doctor':
            report['podman_present'] = shutil.which('podman') is not None
            report['status'] = 'inspected'
            report['note'] = 'Ayuda CLI comprobada; no acredita aislamiento ni autenticación'
        else:
            mission = load_mission(args.mission)
            root = Path(args.root).resolve(strict=True)
            root, tracked = inspect_repository(root, mission)
            report['allowed_paths'] = mission['allowed_paths']
            report['context_paths'] = mission['context_paths']
            report['max_attempts'] = mission['max_attempts']
            report['validation_commands'] = mission['validation_commands']
            report['container_command'] = container_argv(
                mission.get('image', '<IMAGEN_LOCAL>'), '<COPIA_TEMPORAL>', '<NOMBRE>',
                mission.get('network', 'none'), mission['allowed_paths']) + [
                    '-a', 'never', 'exec', '--sandbox', 'workspace-write', '--ephemeral',
                    '--json', '--skip-git-repo-check', '-']
            if args.action == 'plan':
                container_preflight(mission)
                report['status'] = 'planned'
                report['execution_ready'] = False
                report['note'] = 'Sin ejecutar modelo; doctor dentro de imagen y autenticación real pendientes de run'
            else:
                if not mission['validation_commands']:
                    raise Blocked('run requiere al menos un validation_commands antes de ejecutar')
                image = container_preflight(mission)
                execute(mission, root, tracked, image, report)
                report['status'] = 'completed'
    except (Blocked, OSError, subprocess.SubprocessError) as exc:
        report['reason'] = str(exc) if isinstance(exc, Blocked) else type(exc).__name__
    report['runtime_seconds'] = round(time.monotonic() - started, 3)
    if args.action == 'run' and root is not None:
        try:
            target = root / '.ai-local' / 'runs'
            if (root / '.ai-local').is_symlink() or target.is_symlink():
                raise OSError('Directorio de informes inseguro')
            target.mkdir(parents=True, mode=0o700, exist_ok=True)
            file = target / (uuid.uuid4().hex + '.json')
            with file.open('x', encoding='utf-8') as stream:
                os.chmod(file, 0o600)
                json.dump(report, stream, ensure_ascii=False, indent=2)
        except OSError:
            report['log_warning'] = 'No se pudo guardar informe local'
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] not in ('blocked', 'planned') else 2


if __name__ == '__main__':
    sys.exit(main())
