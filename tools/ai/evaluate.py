#!/usr/bin/env python3
"""Evaluación local reproducible. No ejecuta modelos ni accede a otros proyectos."""
import argparse
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
from pathlib import PurePosixPath
import shutil
import statistics
import subprocess
import tempfile
import time

import memory


CASES = [
    ('tecnología', 'por qué se eligió SQLite FTS5',
     {'docs/memory/decisions/AI-001-memoria-local.md', 'docs/ai-system/MEMORY_ARCHITECTURE.md'}),
    ('error histórico', 'error histórico Podman solución',
     {'docs/memory/sessions/2026-11-07-setup.md', 'docs/memory/KNOWN_ISSUES.md',
      'docs/ai-system/RUNBOOK.md'}),
    ('módulo responsable', 'módulo responsable recuperar conocimiento',
     {'docs/memory/MODULE_INDEX.md'}),
    ('rendimiento', 'restricciones rendimiento RAM',
     {'docs/memory/decisions/AI-002-autonomia.md', 'docs/ai-system/AGENT_REGISTRY.md',
      'docs/ai-system/ENVIRONMENT_AUDIT.md'}),
]


def timed(call):
    start = time.perf_counter()
    result = call()
    return result, (time.perf_counter() - start) * 1000


def record(title, body, state='vigente'):
    return (f'# {title}\n\nFuente: fixture de evaluación\nFecha: 2026-11-07\n'
            f'Módulo: evaluación\nEstado: {state}\nDecisión: TEST-001\n'
            f'Evidencia: evaluación local automatizada\n\n{body}\n')


def contradiction_probe():
    with tempfile.TemporaryDirectory(prefix='anime-memory-evaluation-') as folder:
        root = Path(folder)
        docs = root / 'docs/memory'
        docs.mkdir(parents=True)
        (docs / 'a.md').write_text(record('Decisión A', 'Claim: fixture.backend = sqlite'))
        (docs / 'b.md').write_text(record('Decisión B', 'Claim: fixture.backend = vector'))
        (docs / 'old.md').write_text(record('Antigua', 'marcadorobsoleto', 'obsoleta'))
        issues, elapsed = timed(lambda: memory.check(root))
        has_conflict = any('incompatible' in i['issue'] for i in issues)
        has_obsolete = any('obsoleta' in i['issue'] for i in issues)
        hidden = not memory.search(root, 'marcadorobsoleto')
        (docs / 'b.md').write_text(record('Decisión B corregida', 'Claim: fixture.backend = sqlite'))
        (docs / 'old.md').unlink()
        resolved = not memory.check(root)
        return {'name': 'contradicciones y obsolescencia', 'passed': all(
                    (has_conflict, has_obsolete, hidden, resolved)),
                'contradiction_detected': has_conflict, 'obsolete_detected': has_obsolete,
                'obsolete_hidden': hidden, 'resolved_after_correction': resolved,
                'milliseconds': round(elapsed, 3), 'issues': issues,
                'scope': 'fixture explícito, no contradicciones inventadas del producto'}


def git_probe():
    """Ciclo de herramientas real en fixture: memoria→edición→validación→commit."""
    if not shutil.which('git'):
        return {'passed': False, 'reason': 'Git no disponible'}
    with tempfile.TemporaryDirectory(prefix='anime-e2e-') as folder:
        root = Path(folder)

        def git(*args):
            result = subprocess.run(['git', '-C', str(root), '-c', 'user.name=AI Fixture',
                                     '-c', 'user.email=fixture@example.invalid', *args],
                                    capture_output=True, text=True, timeout=15, check=True)
            return result.stdout.strip()

        git('init', '--initial-branch=ai/evaluation')
        docs = root / 'docs/memory'
        docs.mkdir(parents=True)
        (root / 'AGENTS.md').write_text('Solo prueba de infraestructura; no producto.\n')
        (root / '.gitignore').write_text('.ai-local/\n')
        (docs / 'PROJECT_STATE.md').write_text(record('Estado', 'Objetivo: probar memoria sin producto.'))
        (docs / 'AI_HANDOFF.md').write_text(record('Traspaso', 'Siguiente tarea: validar una frase inocua.'))
        git('add', '--', 'AGENTS.md', '.gitignore', 'docs/memory')
        git('commit', '-m', 'test(ai): prepare isolated evaluation fixture')
        found = memory.search(root, 'objetivo memoria', limit=2, max_chars=1600)
        assert found, 'No se recuperó memoria del fixture'
        probe = root / 'probe.txt'
        probe.write_text('Memoria recuperada; prueba de infraestructura correcta.\n')
        assert probe.read_text().startswith('Memoria recuperada;')
        session = docs / 'session.md'
        session.write_text(record('Prueba integral', 'Validación local pasada; sin funcionalidades de producto.'))
        assert not memory.check(root), 'Metadata de fixture inválida'
        handoff = memory.handoff(root, max_chars=1800)
        git('add', '--', 'probe.txt', 'docs/memory/session.md')
        git('diff', '--cached', '--check')
        git('commit', '-m', 'test(ai): validate memory and record harmless probe')
        commit = git('rev-parse', 'HEAD')
        clean = not git('status', '--porcelain')
        return {'passed': clean and bool(handoff), 'branch': 'ai/evaluation',
                'commit': commit, 'clean': clean,
                'scope': 'Git y herramientas reales en fixture temporal; no invoca modelo, red ni Podman',
                'steps': ['leer instrucciones', 'recuperar memoria', 'editar probe.txt',
                          'validar contenido', 'registrar episodio', 'comprobar metadata',
                          'preparar traspaso', 'revisar staged', 'commit local', 'Git limpio']}


def validate_backups(root):
    """Comprueba copias locales sin seguir enlaces ni rutas del manifiesto externas."""
    root = Path(root).resolve()
    backup = root / '.ai-local/backups/initial-20261107'
    for path in (root / '.ai-local', root / '.ai-local/backups', backup):
        if path.is_symlink():
            return False
    manifest_file = backup / 'SHA256.json'
    if not manifest_file.exists():
        return None
    if manifest_file.is_symlink() or not manifest_file.is_file():
        return False
    try:
        with manifest_file.open('rb') as stream:
            raw = stream.read(16385)
        if len(raw) > 16384:
            return False
        manifest = json.loads(raw)
        if not isinstance(manifest, dict) or not 1 <= len(manifest) <= 100:
            return False
        for relative, expected in manifest.items():
            if not isinstance(relative, str) or not isinstance(expected, str):
                return False
            name = PurePosixPath(relative)
            if (name.is_absolute() or str(name) != relative or '\\' in relative
                    or any(part in ('.', '..') for part in name.parts)
                    or not (relative == 'AGENTS.md' or
                            (relative.startswith('.codex/') and relative.endswith('.toml')))):
                return False
            path = backup
            for part in name.parts:
                path = path / part
                if path.is_symlink():
                    return False
            if not path.is_file() or path.stat().st_size > 4 * 1024 * 1024:
                return False
            digest = hashlib.sha256()
            with path.open('rb') as stream:
                total = 0
                while data := stream.read(65536):
                    total += len(data)
                    if total > 4 * 1024 * 1024:
                        return False
                    digest.update(data)
            if digest.hexdigest() != expected:
                return False
        return True
    except (OSError, ValueError, TypeError):
        return False


def successful(report):
    return (all(r['passed'] for r in report['recovery_cases'])
            and not report['memory_lint_issues']
            and report['toolchain_fixture'].get('passed')
            and report['backup_hashes_valid'] is not False)


def evaluate(root):
    files = list(memory.documents(root))
    # Línea base explícita: leer todo el corpus documental, no todo el código.
    baseline_samples = []
    for _ in range(3):
        baseline, elapsed = timed(lambda: '\n'.join(p.read_text(encoding='utf-8') for p in files))
        baseline_samples.append(elapsed)
    corpus_chars = len(baseline)
    results = []
    for name, query, relevant in CASES:
        samples = []
        for _ in range(3):
            found, elapsed = timed(lambda: memory.search(root, query, limit=3, max_chars=3000))
            samples.append(elapsed)
        paths = [r['path'] for r in found]
        size = len(json.dumps(found, ensure_ascii=False))
        top1 = bool(paths and paths[0] in relevant)
        precision = sum(p in relevant for p in paths) / len(paths) if paths else 0
        results.append({'name': name, 'query': query, 'passed': top1,
                        'top1_relevant': top1, 'precision_at_returned_fragments': round(precision, 3),
                        'documents': sorted(set(paths)), 'fragments': len(found),
                        'relevant_paths_declared': sorted(relevant),
                        'milliseconds_median': round(statistics.median(samples), 3),
                        'context_characters': size, 'tokens_proxy_chars_div_4': math.ceil(size / 4),
                        'context_reduction_percent': round(100 * (1 - size / max(corpus_chars, 1)), 2)})
    handoff, elapsed = timed(lambda: memory.handoff(root, max_chars=6000))
    handoff_paths = {r['path'] for r in handoff}
    handoff_ok = {'docs/memory/PROJECT_STATE.md', 'docs/memory/AI_HANDOFF.md'} <= handoff_paths
    handoff_size = len(json.dumps(handoff, ensure_ascii=False))
    results.append({'name': 'contexto para otra IA', 'passed': handoff_ok,
                    'documents': sorted(handoff_paths), 'milliseconds': round(elapsed, 3),
                    'context_characters': handoff_size,
                    'tokens_proxy_chars_div_4': math.ceil(handoff_size / 4),
                    'truncated': any(r.get('truncated') for r in handoff)})
    results.append(contradiction_probe())
    lint = memory.check(root)
    backup_ok = validate_backups(root)
    return {'date': '2026-11-07', 'timezone': 'America/Bogota',
            'measured_at_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
            'baseline': {'documents': len(files), 'characters': corpus_chars,
                         'tokens_proxy_chars_div_4': math.ceil(corpus_chars / 4),
                         'milliseconds_median': round(statistics.median(baseline_samples), 3),
                         'method': 'lectura del corpus Markdown completo; sin invocar modelo'},
            'recovery_cases': results, 'memory_lint_issues': lint,
            'backup_hashes_valid': backup_ok, 'toolchain_fixture': git_probe(),
            'model_usage': {'input_tokens': None, 'output_tokens': None,
                            'cached_input_tokens': None, 'model_calls': None, 'estimated_cost': None},
            'limitations': ['proxy de contexto no es facturación ni tokenizer',
                            'fixture Git no certifica runner nocturno',
                            'no hay código de producto en este proyecto']}


def markdown(report):
    rows = '\n'.join(f"| {r['name']} | {'OK' if r['passed'] else 'FALLO'} | "
                     f"{r.get('precision_at_returned_fragments', '—')} | "
                     f"{r.get('milliseconds_median', r.get('milliseconds', '—'))} | "
                     f"{r.get('tokens_proxy_chars_div_4', '—')} |"
                     for r in report['recovery_cases'])
    baseline = report['baseline']
    return (f'# Evaluación reproducible\n\nFecha local: {report["date"]}, Bogotá. '
            'Ejecutar `python3 tools/ai/evaluate.py --write-report` desde la raíz. '
            'Detalle de consultas, documentos, precisión, tiempos y contexto: [evaluation.json](evaluation.json).\n\n'
            f'Línea base: {baseline["documents"]} documentos, {baseline["characters"]} caracteres, '
            f'{baseline["tokens_proxy_chars_div_4"]} tokens proxy, '
            f'{baseline["milliseconds_median"]} ms de lectura mediana. '
            'Se compara la lectura completa del mismo corpus con tres consultas medidas por pregunta; '
            'la búsqueda incluye reconstrucción del índice. No se afirma que FTS sea más rápido que leer un corpus pequeño.\n\n'
            '| Prueba | Resultado | Precisión fragmentos | ms | Tokens proxy |\n'
            '| --- | --- | --- | --- | --- |\n' + rows + '\n\n'
            'Se exige fuente relevante en primera posición para las cuatro consultas de recuperación. '
            'La precisión de fragmentos adicionales se publica sin ocultar resultados menos pertinentes. '
            'Las fuentes esperadas están declaradas en el evaluador; es un benchmark pequeño del entorno IA, no del producto.\n\n'
            'Contradicciones/obsolescencia: fixture explícito con dos Claims incompatibles y registro obsoleto; '
            'se comprueba detección, exclusión de búsqueda y corrección. El linter no infiere contradicciones semánticas generales.\n\n'
            f'Lint memoria canónica: {len(report["memory_lint_issues"])} problemas. '
            f'Respaldos SHA256 verificados: {report["backup_hashes_valid"]}.\n\n'
            f'Fixture integral de herramientas/Git: {report["toolchain_fixture"].get("passed")}; '
            f'commit de prueba {report["toolchain_fixture"].get("commit", "no disponible")}, '
            'rama ai/evaluation y estado limpio en repositorio temporal. Ese fixture se retira al terminar; '
            'no es el commit de entrega ni llama a un modelo.\n\n'
            'Delegación real y consulta pública: [DELEGATION_PROBE.md](DELEGATION_PROBE.md). '
            'Las pruebas unitarias de aislamiento usan dobles; proveedor y ejecución nocturna reales siguen sin certificarse. '
            'Estado final de pruebas y prerrequisitos: [FINAL_REPORT.md](FINAL_REPORT.md).\n\n'
            'Tokens proxy = ceil(caracteres/4), aproximación de tamaño de contexto, no tokenizer ni coste real. '
            'Tokens facturados, llamadas del modelo y coste de esta sesión no se exponen: null. '
            'No hay suscripciones añadidas ni embeddings instalados.\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-report', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    report = evaluate(root)
    if args.write_report:
        folder = root / 'docs/ai-system'
        (folder / 'evaluation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        (folder / 'EVALUATION.md').write_text(markdown(report))
    summary = {'recovery_passed': sum(r['passed'] for r in report['recovery_cases']),
               'recovery_total': len(report['recovery_cases']),
               'lint_issues': len(report['memory_lint_issues']),
               'fixture_passed': report['toolchain_fixture'].get('passed'),
               'backup_hashes_valid': report['backup_hashes_valid']}
    print(json.dumps(summary, ensure_ascii=False))
    return 0 if successful(report) else 1


if __name__ == '__main__':
    raise SystemExit(main())
