"""Rebuild local contract indexes and proposed maps; never edit product sources."""
from pathlib import Path
import collections
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/refactor'
lib = ROOT / 'app/lib'
files = sorted(p for p in lib.rglob('*') if p.is_file() and not p.is_symlink())
texts = {p.relative_to(ROOT).as_posix(): p.read_text() for p in files}

def table(headers, rows):
    def esc(x):
        return str(x).replace('|', '\\|').replace('\n', ' ')
    return '\n'.join(['| ' + ' | '.join(headers) + ' |', '| ' + ' | '.join(['---']*len(headers)) + ' |'] + ['| ' + ' | '.join(map(esc, row)) + ' |' for row in rows]) + '\n'

def target(path):
    rules = [
      ('app/lib/data/player/providers/', 'app/lib/sources/'),
      ('app/lib/data/player/engine/', 'app/lib/data/services/player/'),
      ('app/lib/application/player/', 'app/lib/features/player/view_model/'),
      ('app/lib/app/player/', 'app/lib/features/player/view/'),
      ('app/lib/app/theme/', 'app/lib/core/theme/'),
      ('app/lib/app/home/', 'app/lib/features/home/view/'),
      ('app/lib/data/anilist/', 'app/lib/data/services/anilist/'),
      ('app/lib/data/kitsu/', 'app/lib/data/services/kitsu/'),
    ]
    if path.startswith('app/lib/app/catalog/detail/'):
        return path.replace('app/lib/app/catalog/detail/', 'app/lib/features/detail/widgets/', 1)
    if path.startswith('app/lib/app/catalog/'):
        name = Path(path).name
        if name == 'README.md': return 'app/lib/features/home/view/catalog_README.md'
        feature = 'search' if 'search' in name else 'detail' if 'detail' in name else 'home'
        folder = 'view_model' if 'module' in name else 'view'
        return f'app/lib/features/{feature}/{folder}/{name}'
    if path.startswith('app/lib/app/') and path.endswith('anime_app.dart'):
        return 'app/lib/core/bootstrap/anime_app.dart'
    for before, after in rules:
        if path.startswith(before): return after + path[len(before):]
    return path

symbols=[]
for line in (OUT/'snapshot_api.txt').read_text().splitlines():
    m=re.match(r'(.+?):(\d+): (.*)', line)
    if m: symbols.append((m[1],int(m[2]),m[3]))
entries=[]
for path,line,symbol in symbols:
    entries.append((f'S{len(entries)+1:04}', 'símbolo',path,line,symbol))
patterns={
 'endpoint/cabecera/parámetro':r'https?://|Uri\.(?:https|http)|allowedHosts|queryParameters|headers|query:|path:|data:|body:|["\x27](?:Origin|Referer|User-Agent|Sec-Fetch-Site)["\x27]|/api/|/graphql|/health',
 'ruta/pantalla':r'Navigator\.|MaterialPageRoute|GoRoute|class \w*(?:Page|Route|Screen)\b|initialRoute|routeName',
 'persistencia':r'schemaVersion|CREATE TABLE|tableName|PRIMARY KEY|preferences|storageKey|cacheKey|credential|settingsKey|read\(key:|write\(key:|delete\(key:|TextColumn|IntColumn|DateTimeColumn|BoolColumn|BlobColumn|SettingDefinition|key:|key =|key =>',
 'configuración':r'Platform\.environment|String\.fromEnvironment|bool\.fromEnvironment',
}
references=[]
for path,text in texts.items():
    for line_no,line in enumerate(text.splitlines(),1):
        for kind,pattern in patterns.items():
            if re.search(pattern,line):
                entries.append((f'C{len(references)+1:04}',kind,path,line_no,line.strip()))
                references.append(entries[-1])
# Full files preserve expressions split across lines, dynamic URL composition and keys.
protected=[p for p in texts if p.endswith('.dart') and ('/providers/' in p or '/anilist/' in p or '/kitsu/' in p or '/local_db/' in p or '/secure_storage/' in p or '/settings/' in p)]
(OUT/'CONTRATOS_REFERENCIAS.md').write_text('# Registro de contratos\n\nIDs estables en esta captura; los fragmentos multilínea se interpretan con el archivo fuente completo.\n\n'+table(['ID','Tipo','Archivo:línea','Declaración / expresión'],[(i,k,f'{p}:{n}',v) for i,k,p,n,v in entries]))
(OUT/'REFERENCIAS.txt').write_text('\n'.join(f'{p}:{n}: {v}' for _,_,p,n,v in references)+'\n')
(OUT/'protected-sha256.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in protected},indent=2)+'\n')
manifest=(ROOT/'app/pubspec.yaml').read_text()
platforms=[]
for p in sorted((ROOT/'app').iterdir()):
    if p.is_dir() and p.name in ('android','linux','windows','macos','ios','web'):
        platforms.append(p.name)
assets=[p for p in files if p.suffix!='.dart']
config_paths=[p for p in subprocess.check_output(['git','ls-files','app/linux','app/android','app/windows','app/ios','app/macos','app/web'],cwd=ROOT,text=True).splitlines() if '/ephemeral/' not in p]
(OUT/'PLATAFORMAS.md').write_text('# Configuración por plataforma\n\nDirectorios presentes: '+', '.join(platforms)+'. Android/Windows no tienen scaffold en este árbol.\nNo inventar permisos ni configuraciones ausentes.\n\n'+''.join('## '+p+'\n\n```\n'+(ROOT/p).read_text()+'\n```\n\n' for p in config_paths if Path(p).suffix in ('.txt','.cmake','.h','.cc') or 'CMakeLists' in p))
(OUT/'INVENTARIO.md').write_text('''# Inventario contractual — 2026-11-20

Captura del árbol respaldado por `507368b177a1b096ae4cfae9f3c0094f658693c8`.
No se ha cambiado lógica. Todos los elementos conservan ubicación actual.
El registro [CONTRATOS_REFERENCIAS](CONTRATOS_REFERENCIAS.md) enumera símbolos,
endpoints/cabeceras/parámetros, pantallas/rutas, persistencia y configuración.
`snapshot_api.txt` se obtiene con AST, incluyendo getters, constructores y campos;
`API_PARSE_ERRORS.txt` declara los errores sintácticos previos que limitan el AST.
Los archivos con errores conservan hash y fuente completa en el commit de respaldo:
la lista de sus símbolos es recuperada por el parser, no certificada semánticamente.
No interpretar nombres dinámicos de claves o rutas interpoladas como constantes.

'''+table(['Categoría','Elementos registrados'],collections.Counter(e[1] for e in entries).items())+'''
## Servicios, repositorios y scrapers

Todos sus símbolos públicos están individualizados por ID en el registro;
`PROTEGIDO.md` añade callers, cobertura y hashes de los módulos protegidos.
Los servicios existentes de catálogo son AniList/Kitsu; no se sustituirán por MAL.
El identificador MyAnimeList en proveedores no acredita un catálogo MAL conectado.

## Persistencia

Se conserva Drift schemaVersion 9, tablas, migraciones y JSON opaco, identificadores,
claves de caché, settings, credenciales y progreso. El registro incluye las líneas
que los definen; el hash del archivo protege también expresiones multilinea.
No modificar esquema, codecs ni precedencia en un movimiento.

## Assets y dependencias

El manifiesto no declara assets ni fuentes de aplicación; `uses-material-design`
se conserva. Los README bajo lib no son assets runtime. Recursos de plataforma
se inventarían en PLATAFORMAS y en el mapa de todos los archivos, sin borrarlos.

```yaml
'''+manifest+'\n```\n\n## Permisos y configuración por plataforma\n\nVer [PLATAFORMAS](PLATAFORMAS.md): cada configuración presente se conserva literal.\nAndroid y Windows no verificables; no se ha añadido ningún scaffold.\n')
# Public dependency graph, including relative and package imports.
graph={p:[] for p in texts if p.endswith('.dart')}
for p in graph:
    for uri in re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)['\"]",texts[p]):
        if uri.startswith('package:anime_app/'):
            dep='app/lib/'+uri.split('/',1)[1]
        elif ':' not in uri:
            dep=str((ROOT/p).parent.joinpath(uri).resolve().relative_to(ROOT))
        else: continue
        if dep in graph: graph[p].append(dep)
# Tarjan components.
index={}; low={}; stack=[]; on=set(); components=[]
def visit(v):
    index[v]=low[v]=len(index); stack.append(v);on.add(v)
    for w in graph[v]:
        if w not in index: visit(w);low[v]=min(low[v],low[w])
        elif w in on: low[v]=min(low[v],index[w])
    if low[v]==index[v]:
        group=[]
        while True:
            w=stack.pop();on.remove(w);group.append(w)
            if w==v: break
        if len(group)>1: components.append(group)
for p in graph:
    if p not in index:visit(p)
(OUT/'IMPORTS.md').write_text('# Graphe de dependencias estáticas\n\nSe incluyen import/export/part de package:anime_app y rutas relativas.\nUna SCC con part generado no demuestra acoplamiento funcional.\n\n'+table(['Archivo','Dependencias'],[(p,', '.join(deps)) for p,deps in graph.items()])+ '\n## Componentes fuertemente conexas\n\n'+ ''.join('- '+', '.join(c)+'\n' for c in components))
caller_tests=[p for p in (ROOT/'app/test').rglob('*test.dart') if p.is_file() and not p.is_symlink()]
coverage=[]
for path in protected:
    basename=Path(path).name
    callers=[p for p,t in texts.items() if p!=path and (f"'{basename}'" in t or path.removeprefix('app/lib/') in t or ('/'+basename+"'") in t)]
    tests=[p.relative_to(ROOT).as_posix() for p in caller_tests if basename in p.read_text()]
    if 'html_playback_parsers' in path or 'miruro_catalog_parser' in path or 'animeav1_playback_provider' in path:
        tests.append('app/test/refactor/parser_characterization_test.dart (golden)')
    if any(f'/{key}/' in path for key in ('allanime','animeav1','animegg','anizone','megaplay','wikimedia')) or 'voe_video_host_resolver.dart' in path:
        tests.append('app/test/refactor/source_characterization_test.dart (golden de datos + HTTP)')
    if any(key in path for key in ('miruro_catalog_api.dart','direct_media_host_resolver.dart','user_defined_playback_provider.dart')):
        tests.append('app/test/refactor/transport_characterization_test.dart (golden)')
    desc=', '.join(tests) if tests else 'SIN TEST DIRECTO (cobertura transitiva no atribuida)'
    coverage.append((path,', '.join(f'{sig[:90]} @{n}' for p,n,sig in symbols if p==path),', '.join(callers) or 'sin caller estático directo identificado',desc))
(OUT/'PROTEGIDO.md').write_text('''# Zona protegida

No alterar lógica, regex, firmas, tokens de protocolo, cookies ficticias de tests,
headers, endpoints ni orden de operaciones. No copiar credenciales reales a fixtures.
Al mover: comparar contenido sin imports, todas las expectativas y hashes antes/después.
No introducir un adaptador nuevo si ya existe el contrato EpisodeSourceAdapter /
PlaybackSourceProvider. Persistencia y codecs también están protegidos.

La tabla diferencia tests directos existentes de golden nuevos. Un import de test
no demuestra ejecución ni éxito: consultar logs; varios no compilan por el manager.
Los `SIN TEST DIRECTO` se caracterizan antes de cualquier movimiento.

'''+table(['Archivo','Símbolos públicos y líneas','Quién lo llama','Cobertura directa'],coverage))
# Findings: structural facts plus explicit, reviewed problems.
findings=[]
def finding(path,start,end,kind,severity,risk,description,proposal,status='confirmado por lectura'):
    findings.append((f'A{len(findings)+1:03}',f'{path}:{start}-{end}',kind,severity,risk,status,description,proposal))
for path,text in texts.items():
    count=len(text.splitlines())
    if path.endswith('.dart') and count>250:
        generated=path.endswith('.g.dart')
        finding(path,1,count,'archivo >250','baja' if generated else 'media','alto' if '/providers/' in path or generated else 'medio',f'{count} líneas'+('; generado, no dividir a mano' if generated else ''),'Conservar generado' if generated else 'Dividir por responsabilidad en fase propia; fuentes solo mover.')
widgets=OUT/'WIDGET_SIZES.txt'
if widgets.exists():
    for line in widgets.read_text().splitlines():
        m=re.match(r'(.+?):(\d+):(\d+): (.*)',line)
        if m and int(m[3])-int(m[2])+1>120:
            finding(m[1],int(m[2]),int(m[3]),'widget/State >120','media','medio','Clase UI excede 120 líneas; no equivale al tamaño de build().','Extraer widgets const y estado local sin cambiar callbacks.')
finding('app/lib/application/player/providers/playback_provider_manager.dart',205,300,'contrato/sintaxis','alta','alto','Manager no compila; diagnósticos de analyze y tests integrados.','Corrección funcional separada y autorizada antes de mover; no implementada.')
finding('app/lib/data/player/providers/jkanime/jkanime_playback_provider.dart',60,80,'scraper inválido','alta','alto','Regex/cadena y contratos presentan diagnósticos de análisis previos.','No modificar scraper; resolver bloqueo en tarea explícita y caracterizarlo.')
finding('app/lib/main.dart',33,36,'contrato bootstrap','alta','alto','miruroProxy no existe en firma invocada.','Resolver contrato en tarea separada; no ocultar en refactor.')
finding('app/lib/app/catalog/catalog_home_page.dart',145,231,'negocio en widget','media','medio','Widget coordina resolver, progreso, identidad y navegación. Guardas mounted presentes.','Extraer coordinación a view_model; conservar secuencia y cancelación.')
finding('app/lib/main.dart',103,124,'recurso/isolate/errores','alta','alto','Isolate.spawn no esperado ni retenido; Future de probeHealth sin await, catch síncrono no observa su fallo asíncrono; sleep bloquea isolate. Riesgo de lifecycle, no medido.','Fase funcional separada: owner/cancelación y tests negativos; no implementarla aquí.')
finding('app/lib/data/player/providers/miruro/miruro_catalog_api.dart',160,190,'parseo hilo UI','media','alto','XOR y gzip síncronos; no hay medición del coste en UI.','Perf posterior: medir; solo envolver sin cambiar parser si resulta costoso.', 'riesgo no medido')
finding('app/lib/main.dart',20,22,'constantes/caché','baja','medio','Límite existente 120 imágenes / 48 MiB; ya hay ajuste de memoria.','Conservar default; no volver a recortarlo sin medir.')
finding('app/lib/main.dart',87,101,'código aparentemente muerto','baja','alto','probeLoop local no invocado; analyzer unused_element.','Listar para decisión del propietario, nunca borrar ni mover a legacy por inferencia.')
finding('app/lib/main.dart',136,136,'errores/logs','baja','medio','stderr.writeln fuera del logger estructurado.','Unificar en fase separada preservando mensaje y comportamiento.')
# Syntax-valid duplication evidence is exact non-empty line blocks, never auto-delete.
blocks=collections.defaultdict(set)
for path,text in texts.items():
    if path.endswith('.g.dart'):continue
    lines=text.splitlines()
    for n in range(len(lines)-7):
        chunk='\n'.join(lines[n:n+8])
        if len(chunk)>220 and 'import ' not in chunk:
            blocks[chunk].add(path)
duplicates=[(sorted(v),k) for k,v in blocks.items() if len(v)>1]
(OUT/'DUPLICADOS.md').write_text('# Bloques literales repetidos: candidatos\n\nIgualdad textual de 8 líneas, sin imports ni archivos generados. No demuestra igual responsabilidad.\n\n'+table(['Archivos','Bloque'],[(', '.join(paths),chunk) for paths,chunk in duplicates]))
if duplicates:
    paths,chunk=duplicates[0]
    n=texts[paths[0]].splitlines().index(chunk.splitlines()[0])+1
    finding(paths[0],n,n+7,'duplicación literal','baja','alto',f'{len(duplicates)} ventanas repetidas; ver DUPLICADOS, varias se solapan.','No unificar scrapers; validar equivalencia y decisión del propietario primero.','candidato a revisión')
# Audit candidate locations, avoid claiming leaks from lexical matches.
candidates=[]
for path,text in texts.items():
    if path.endswith('.g.dart'): continue
    for n,line in enumerate(text.splitlines(),1):
        for kind,pattern in [('estado/estáticos',r'\bsetState\(|static (?:final|late)|singleton'),('hardcode',r'Color\(0x|Duration\(|https?://'),('recursos',r'Timer\(|\.listen\(|StreamSubscription|Player\(|TextEditingController\('),('errores',r'catch\s*\(|on Object|\bprint\('),('tipado',r'\bdynamic\b|\bas [A-Z]')]:
            if re.search(pattern,line):candidates.append((kind,f'{path}:{n}',line.strip()))
(OUT/'CANDIDATOS.md').write_text('# Ubicaciones para revisión dirigida\n\nCoincidencias léxicas, NO defectos demostrados. Revisar ownership y caller antes de intervenir.\n\n'+table(['Tipo','Archivo:línea','Evidencia'],candidates))
summary=collections.Counter((row[2],row[3],row[4]) for row in findings)
(OUT/'AUDITORIA.md').write_text('''# Auditoría Fase 0 — 2026-11-20

Alcance: código actual sin correcciones. Procedimiento kongroo-deep-audit,
segunda pasada propia, no independiente; sin agentes ni prueba gráfica.
La baseline no compila completa: no se recomienda aceptación técnica ni movimiento.
P1 equivale aquí a severidad alta, P2 media, P3 baja; no se afirma P0.
La fase documental no cierra las fases históricas del reproductor.

'''+table(['ID','Archivo:líneas','Tipo','Severidad','Riesgo al tocar','Estado','Hallazgo','Propuesta'],findings)+'''
## Revisión por categorías y límites

- Acoplamiento: IMPORTS.md registra todo el grafo y las SCC; part generado no es defecto.
- Widgets: se verificó mounted en el flujo de reproducción de catalog_home_page;
  no se encontró allí un uso demostrado de BuildContext tras await sin guarda.
- Estado compartido: setState detectado se lista en CANDIDATOS; no basta para
  afirmar que el estado sea compartido. No cambiar gestor de estado ni navegación.
- Red: el widget invoca coordinador/servicios; no se acreditó un HTTP directo
  dentro de build. La mezcla de responsabilidades sí consta en A de negocio UI.
- Recursos: hay dispose/cancel existentes; no se afirma fuga de Player por mera
  coincidencia léxica. El isolate de main necesita ownership explícito.
- Plataformas: imports dart:io y fronteras de codecs están inventariados; no hay
  scaffolds Android/Windows para verificar aislamiento real en esas plataformas.
- Tipado, catch, constantes y potenciales estáticos: ubicaciones en CANDIDATOS;
  diagnósticos comprobados de tipo/sintaxis en analyze_baseline.txt.
- Dependencias: conservar todas, incluidos plugins sin imports Dart directos.
  pubspec no contiene Riverpod, go_router, freezed ni very_good_analysis.
  No instalar ni migrar estas tecnologías dentro del refactor de paridad.
- Código muerto: solo probeLoop demostrado no referenciado; no eliminar nada.
- Scrapers no guardan en UI sus HTML directamente en el flujo revisado; no se
  ha demostrado mezcla con DB. Preservar transportes y parsers de cada fuente.

## Resumen

'''+table(['Tipo','Cantidad','Severidad','Riesgo'],[(k[0],v,k[1],k[2]) for k,v in summary.items()])+'''
## Segunda pasada adversarial

Se confrontaron diagnóstico de análisis, errores de parseo, imports y resultados
reales de tests; se verificó que los golden no dependan del manager roto. Se añadió
caso de URL pública para evitar una prueba vacía con todas las fuentes rechazadas.
No se declara cobertura completa de proveedores por los golden offline.
Reevaluación: resolver fallos previos en tarea distinta, caracterizar módulos SIN
TEST y comprobar pruebas completas antes de autorizar movimientos.
''')
# Proposed one-to-one map for all existing project files, excluding ignored derived content.
project=sorted(set(subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=ROOT).decode().split('\0'))-{''})
rows=[(p,target(p),'mover' if target(p)!=p else 'conservar') for p in project if Path(p).name!='generate_documents.py']
(OUT/'MAPA_ARCHIVOS.md').write_text('# Mapa completo propuesto; ningún movimiento ejecutado\n\nIncluye archivos versionados y no ignorados presentes al generar. Backups locales y builds ignorados quedan fuera.\n\n'+table(['Actual','Destino propuesto','Acción'],rows))
(OUT/'MATRIZ_PARIDAD.md').write_text('# Matriz individual de paridad\n\nEstado pendiente significa revalidar tras movimiento; el código está presente en el respaldo. No se afirma equivalencia ejecutada.\n\n'+table(['ID','Tipo','Actual','Destino','Estado'],[(i,k,f'{p}:{n}',target(p),'pendiente') for i,k,p,n,_ in entries]))
(OUT/'contract-index.json').write_text(json.dumps([{'id':i,'kind':k,'path':p,'line':n,'value':v,'destination':target(p)} for i,k,p,n,v in entries],ensure_ascii=False,indent=2)+'\n')
print(f'{len(symbols)} symbols, {len(references)} references, {len(rows)} mapped files, {len(findings)} findings.')
