#!/usr/bin/env python3
"""Índice reconstruible de documentación Markdown; solo biblioteca estándar."""
import argparse
from contextlib import contextmanager
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import unicodedata
from urllib.parse import unquote, urlsplit
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

SOURCES = ('docs/ai-system', 'docs/memory', 'docs/architecture', 'docs/perf')
FIELDS = ('Fuente', 'Fecha', 'Módulo', 'Estado', 'Decisión', 'Evidencia')
MAX_DOCUMENT_BYTES = 256 * 1024
MAX_CORPUS_BYTES = 4 * 1024 * 1024
MAX_DOCUMENTS = 500
MAX_METADATA_BYTES = 16 * 1024


def normalize(value):
    return ''.join(c for c in unicodedata.normalize('NFKD', value.casefold())
                   if not unicodedata.combining(c))


def documents(root):
    root = Path(root).resolve()
    count = total = 0
    for source in SOURCES:
        base = root / source
        if not base.is_dir() or base.is_symlink():
            continue
        for path in base.rglob('*.md'):
            relative = path.relative_to(root)
            if any(part.startswith('.') or part in ('node_modules', 'vendor', 'build')
                   for part in relative.parts):
                continue
            if any(parent.is_symlink() for parent in (path, *path.parents)
                   if parent != root and root in parent.parents):
                continue
            if path.is_file() and path.resolve().is_relative_to(root):
                size = path.stat().st_size
                count += 1
                total += size
                if size > MAX_DOCUMENT_BYTES:
                    raise ValueError(f'Documento excede límite de {MAX_DOCUMENT_BYTES} bytes: {relative}')
                if count > MAX_DOCUMENTS:
                    raise ValueError(f'Corpus excede límite de {MAX_DOCUMENTS} documentos')
                if total > MAX_CORPUS_BYTES:
                    raise ValueError(f'Corpus excede límite de {MAX_CORPUS_BYTES} bytes')
                yield path


def read_document(path):
    with path.open('rb') as source:
        raw = source.read(MAX_DOCUMENT_BYTES + 1)
    if len(raw) > MAX_DOCUMENT_BYTES:
        raise ValueError(f'Documento excede límite de {MAX_DOCUMENT_BYTES} bytes: {path.name}')
    return raw


def metadata(text):
    values = {}
    for line in text.splitlines():
        match = re.match(r'^\s*(?:[-*]\s+)?(?:\*\*)?([^:]+?)(?:\*\*)?\s*:\s*(.*?)\s*$', line)
        if match:
            values[normalize(match[1].strip('* '))] = match[2].strip('* ')
    return values


def obsolete(meta):
    return normalize(meta.get('estado', '')) in ('obsoleta', 'obsoleto', 'superseded', 'deprecated', 'archivada', 'archivado')


def fragments(text):
    lines = text.splitlines()
    start = 0
    for index, line in enumerate(lines):
        if index > start and (line.startswith('#') or index - start >= 80):
            yield start + 1, '\n'.join(lines[start:index])
            start = index
    if lines:
        yield start + 1, '\n'.join(lines[start:])


@contextmanager
def connect(root):
    folder = Path(root).resolve() / '.ai-local'
    if folder.is_symlink():
        raise ValueError('.ai-local no puede ser un enlace simbólico')
    folder.mkdir(exist_ok=True)
    database = folder / 'memory.sqlite3'
    if database.is_symlink():
        raise ValueError('La base no puede ser un enlace simbólico')
    db = sqlite3.connect(database)
    try:
        db.row_factory = sqlite3.Row
        db.execute('CREATE VIRTUAL TABLE IF NOT EXISTS fragments USING fts5(path UNINDEXED, line UNINDEXED, hash UNINDEXED, mtime UNINDEXED, obsolete UNINDEXED, body UNINDEXED, tokens)')
        with db:
            yield db
    finally:
        db.close()


def index(root):
    root = Path(root).resolve()
    # Reconstrucción transaccional: elimina también documentos borrados y cambios de estado.
    with connect(root) as db:
        db.execute('DELETE FROM fragments')
        count = 0
        actual_bytes = 0
        for path in documents(root):
            raw = read_document(path)
            actual_bytes += len(raw)
            if actual_bytes > MAX_CORPUS_BYTES:
                raise ValueError(f'Corpus excede límite de {MAX_CORPUS_BYTES} bytes')
            text = raw.decode('utf-8')
            meta = metadata(text)
            for line, body in fragments(text):
                db.execute('INSERT INTO fragments VALUES (?,?,?,?,?,?,?)',
                           (path.relative_to(root).as_posix(), line,
                            hashlib.sha256(raw).hexdigest(), path.stat().st_mtime_ns,
                            int(obsolete(meta)), body, normalize(body)))
                count += 1
    return {'documents': len(list(documents(root))), 'fragments': count}


def bounded(rows, max_chars):
    # El límite corresponde al JSON completo, incluidos identificadores y enlaces.
    result = []
    for original in rows:
        row = dict(original)
        body = row.pop('body', '')
        row['excerpt'] = ''
        row['truncated'] = bool(body)
        if len(json.dumps(result + [row], ensure_ascii=False)) > max_chars:
            break
        low, high = 0, len(body)
        while low < high:
            middle = (low + high + 1) // 2
            row['excerpt'] = body[:middle]
            row['truncated'] = middle < len(body)
            if len(json.dumps(result + [row], ensure_ascii=False)) <= max_chars:
                low = middle
            else:
                high = middle - 1
        row['excerpt'] = body[:low]
        row['truncated'] = low < len(body)
        result.append(row)
    return result


def describe(root, rows):
    """Expone el estado y tipo del documento completo en cada fragmento."""
    root = Path(root).resolve()
    by_path = {}
    result = []
    for row in rows:
        item = dict(row)
        name = item['path']
        if name not in by_path:
            path = root / name
            if not path.resolve().is_relative_to(root) or any(
                    part.is_symlink() for part in (path, *path.parents) if part != root):
                raise ValueError('Ruta de documento insegura: ' + name)
            # La metadata pertenece a la cabecera; no releer el corpus para describir resultados.
            with path.open('rb') as source:
                header = source.read(MAX_METADATA_BYTES).decode('utf-8', errors='replace')
            by_path[name] = metadata(header)
        meta = by_path[name]
        item['state'] = meta.get('estado', 'sin declarar')
        item['kind'] = meta.get('tipo', 'sin declarar')
        result.append(item)
    return result


def search(root, query, limit=5, max_chars=4000, include_obsolete=False):
    index(root)
    terms = re.findall(r'\w+', normalize(query))
    if not terms:
        return []
    expression = ' OR '.join('"' + term + '"' for term in terms)
    with connect(root) as db:
        rows = db.execute('SELECT path,line,hash,mtime,obsolete,body FROM fragments WHERE fragments MATCH ? '
                          + ('' if include_obsolete else 'AND obsolete = 0 ')
                          + 'ORDER BY obsolete ASC, bm25(fragments),path,line LIMIT ?',
                          (expression, min(10, max(1, limit)))).fetchall()
    return bounded(describe(root, rows), max_chars)


def client_date():
    try:
        zone = ZoneInfo('America/Bogota')
    except ZoneInfoNotFoundError:
        zone = dt.timezone.utc
    return dt.datetime.now(zone).date()


def check(root, as_of=None):
    root = Path(root).resolve()
    as_of = as_of or client_date()
    issues, claims = [], {}
    for path in documents(root):
        relative = path.relative_to(root).as_posix()
        if not relative.startswith('docs/memory/') or normalize(path.stem) in ('readme', 'index', 'indice'):
            continue
        text = read_document(path).decode('utf-8')
        meta = metadata(text)
        for field in FIELDS:
            if not meta.get(normalize(field)):
                issues.append({'path': relative, 'issue': 'Falta metadata: ' + field})
        try:
            date = dt.date.fromisoformat(meta.get('fecha', ''))
            if date > as_of:
                issues.append({'path': relative, 'issue': 'Fecha futura'})
        except ValueError:
            issues.append({'path': relative, 'issue': 'Fecha inválida (usar YYYY-MM-DD)'})
        if obsolete(meta):
            issues.append({'path': relative, 'issue': 'Memoria obsoleta'})
        research = normalize(meta.get('tipo', '')) in ('investigacion', 'research') or 'investigacion' in normalize(relative)
        if research and normalize(meta.get('estado', '')) in ('aprobada', 'aprobado', 'vigente'):
            issues.append({'path': relative, 'issue': 'Investigación marcada como decisión vigente; separar tipos'})
        for link in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
            parsed = urlsplit(link)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            target = (path.parent / unquote(parsed.path)).resolve()
            if not target.is_relative_to(root) or not target.exists():
                issues.append({'path': relative, 'issue': 'Enlace local roto o fuera del proyecto: ' + link})
        # Contrato opcional: Claim: clave = valor; solo decisiones vigentes.
        if not obsolete(meta) and not research:
            for key, value in re.findall(r'^Claim:\s*([^=\n]+)=\s*(.+)$', text, re.M):
                key, value = normalize(key.strip()), value.strip()
                if key in claims and claims[key][0] != value:
                    issues.append({'path': relative, 'issue': 'Claim incompatible: ' + key,
                                   'conflicts_with': claims[key][1]})
                else:
                    claims[key] = (value, relative)
    return issues


def clean_excerpt(text):
    fields = {normalize(field) for field in (*FIELDS, 'Tipo', 'Claim')}
    output = []
    for line in text.splitlines():
        match = re.match(r'^\s*(?:[-*]\s+)?(?:\*\*)?([^:]+?)(?:\*\*)?\s*:', line)
        if match and normalize(match[1].strip('* ')) in fields:
            continue
        output.append(line)
    return '\n'.join(output).strip()


def handoff(root, max_chars=4000):
    index(root)
    priority = ('PROJECT_STATE', 'AI_HANDOFF', 'KNOWN_ISSUES',
                'ARCHITECTURE_INDEX', 'MODULE_INDEX', 'DECISIONS')
    with connect(root) as db:
        paths = db.execute('SELECT DISTINCT path FROM fragments WHERE obsolete=0 ORDER BY path LIMIT ?',
                           (MAX_DOCUMENTS,)).fetchall()
        def path_order(row):
            stem = Path(row['path']).stem.upper()
            return (priority.index(stem) if stem in priority else len(priority), row['path'])
        paths = sorted(paths, key=path_order)[:6]
        rows = []
        # Hasta doce secciones; las claves operativas se buscan también al final.
        cap = min(max_chars, 4096)
        piece_cap = max(1, cap // 12)
        for entry in paths:
            keys = ['objetivo', 'estado', 'siguiente', 'restricciones', 'comandos']
            if Path(entry['path']).stem.upper() == 'AI_HANDOFF':
                keys = ['siguiente', 'objetivo', 'estado', 'restricciones', 'comandos']
            heading = "substr(tokens,1,instr(tokens||char(10),char(10))-1)"
            ranking = 'CASE ' + ' '.join(
                f'WHEN instr({heading},?)>0 THEN {rank}' for rank in range(len(keys))) + ' ELSE 5 END'
            pieces = db.execute('SELECT line,substr(body,1,?) AS body,length(body) AS size '
                                'FROM fragments WHERE path=? AND obsolete=0 ORDER BY ' + ranking +
                                ',CAST(line AS INTEGER) LIMIT 12', (piece_cap, entry['path'], *keys)).fetchall()
            quota = max(1, (cap - len(pieces)) // len(pieces))
            body = '\n'.join(clean_excerpt(piece['body'])[:quota] for piece in pieces)[:cap]
            rows.append({'path': entry['path'], 'line': pieces[0]['line'], 'body': body,
                         'source_truncated': len(pieces) == 12 or any(
                             piece['size'] > min(quota, len(piece['body'])) for piece in pieces)})
    grouped = {}
    for row in describe(root, rows):
        path = row['path']
        if path in grouped:
            grouped[path]['body'] += '\n' + row['body']
        else:
            grouped[path] = row

    def order(row):
        stem = Path(row['path']).stem.upper()
        rank = priority.index(stem) if stem in priority else len(priority)
        return rank, row['path']

    sources = sorted(grouped.values(), key=order)
    selected = []
    # Reserva contenido por fuente antes de repartir el espacio restante.
    for source in sources:
        candidate = {key: value for key, value in source.items() if key not in ('body', 'source_truncated')}
        candidate.update(excerpt=source['body'][:48], truncated=True)
        if len(json.dumps(selected + [candidate], ensure_ascii=False)) > max_chars:
            break
        selected.append(candidate)
    if sources and not selected:
        raise ValueError('Presupuesto insuficiente para conservar el primer enlace; aumente --max-chars')
    if not selected:
        return []
    # Búsqueda binaria de una cuota común: un documento largo no desplaza a los demás.
    low, high = 0, max(len(source['body']) for source in sources[:len(selected)])
    def render(quota):
        result = []
        for source in sources[:len(selected)]:
            item = {key: value for key, value in source.items() if key not in ('body', 'source_truncated')}
            item.update(excerpt=source['body'][:quota],
                        truncated=source['source_truncated'] or len(source['body']) > quota)
            result.append(item)
        return result
    while low < high:
        middle = (low + high + 1) // 2
        if len(json.dumps(render(middle), ensure_ascii=False)) <= max_chars:
            low = middle
        else:
            high = middle - 1
    return render(low)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--json', action='store_true', help='Salida JSON estructurada')
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('index')
    checker = commands.add_parser('check')
    checker.add_argument('--as-of', type=dt.date.fromisoformat,
                         help='Fecha de referencia YYYY-MM-DD (predeterminado: Bogotá)')
    for name in ('search', 'handoff'):
        sub = commands.add_parser(name)
        sub.add_argument('--max-chars', type=int, default=4000)
        if name == 'search':
            sub.add_argument('query')
            sub.add_argument('--limit', type=int, choices=range(1, 11), default=5)
            sub.add_argument('--include-obsolete', action='store_true')
    args = parser.parse_args()
    if not args.root.is_dir():
        parser.error('--root debe ser un directorio existente')
    if hasattr(args, 'max_chars') and args.max_chars < 256:
        parser.error('--max-chars debe ser al menos 256')
    try:
        if args.command == 'search':
            result = search(args.root, args.query, args.limit, args.max_chars, args.include_obsolete)
        elif args.command == 'handoff':
            result = handoff(args.root, args.max_chars)
        elif args.command == 'index':
            result = index(args.root)
        else:
            result = check(args.root, args.as_of)
    except (OSError, ValueError, sqlite3.Error) as error:
        parser.exit(2, 'Error: ' + str(error) + '\n')
    # JSON también es el formato textual predeterminado para preservar el presupuesto.
    print(json.dumps(result, ensure_ascii=False))
    return 1 if args.command == 'check' and result else 0


if __name__ == '__main__':
    raise SystemExit(main())
