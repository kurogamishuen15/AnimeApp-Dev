# Operación y recuperación

**Límite permanente:** ejecutar los comandos desde la raíz autorizada y restringir toda inspección a ella y sus subcarpetas. No usar búsquedas en directorios padres, Imágenes u otras rutas. No seguir symlinks que salgan del proyecto. Una dependencia externa es un bloqueo que se documenta; no se busca fuera.

## Comprobación inicial

```bash
git status --short --branch
git diff --cached --stat
python3 tools/ai/memory.py check
python3 tools/ai/memory.py handoff --max-chars 6000
python3 tools/ai/autonomy.py doctor
```

Leer FINAL_REPORT y KNOWN_ISSUES. No interpretar la existencia de .git como prueba de repositorio: usar git rev-parse. No limpiar cambios previos. La configuración raíz mantiene modelo y esfuerzo heredados; el modo nocturno necesita prerrequisitos adicionales.

## Memoria y evaluación

```bash
python3 tools/ai/memory.py index
python3 tools/ai/memory.py search "tecnología memoria SQLite" --limit 5 --max-chars 4000
python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v
python3 tools/ai/evaluate.py
```

La evaluación imprime un resumen JSON y actualiza únicamente el reporte autorizado si se pasa --write-report. Mantener metadata al inicio y no almacenar secretos. Si SQLite está dañado, volver a indexar; si no abre, mover únicamente memory.sqlite3 a un nombre de diagnóstico local y ejecutar index. No borrar toda .ai-local: contiene respaldos y registros.

## Misión desatendida: preparar, no improvisar

Ejemplo en `tools/ai/missions/smoke.json`. Las rutas allowed_paths son archivos exactos existentes y rastreados. context_paths declara todos los archivos de lectura necesarios, incluyendo instrucciones y herramientas; no se copia el repositorio completo. Rechazar secretos incluso si por error están versionados.

```bash
python3 tools/ai/autonomy.py plan --root . --mission tools/ai/missions/smoke.json
python3 tools/ai/autonomy.py run --root . --mission tools/ai/missions/smoke.json
```

El ejemplo bloquea deliberadamente sin imagen/proveedor verificados. No cambiar network o broker_prepared solo para lograr salida cero. Aprovisionar imagen sin credenciales, verificar digest/capacidades, preparar proveedor por un canal autorizado y repetir una misión inocua. plan no certifica readiness; run debe verificar proveedor y validaciones antes de integrar. El timeout incluye comprobaciones y pruebas; no se reintenta sin progreso.

tmux solo se utilizará después de esa validación. Inicio manual desde la raíz: `tmux new-session -s animeapp-ai`, ejecutar run dentro de ella y desacoplar con Ctrl-b d. Recuperar con `tmux attach -t animeapp-ai`. No registrar secretos en terminal. No hay garantía de supervivencia a reinicios ni reanudación automática.

## Copias y recuperación de configuración

Copias iniciales: `.ai-local/backups/initial-20261107/`. El manifiesto SHA256 se comprueba antes de restaurar. Para cada archivo a restaurar: verificar hash de la copia, revisar diff contra el actual, guardar copia del actual con fecha y copiar únicamente ese archivo tras una decisión explícita. No ejecutar una restauración masiva ni borrar archivos nuevos automáticamente.

El respaldo inicial conserva AGENTS y configuración/perfiles previos. Los índices y reportes derivados no sustituyen una copia del código. Antes de futuras modificaciones de configuración, crear una nueva copia y manifiesto; nunca sobrescribir un respaldo existente que difiera.

## Git y commits locales

Para AnimeApp, la política canónica está en [CONTRIBUTING.md](../../CONTRIBUTING.md) y el procedimiento de publicación en [RELEASING.md](../../RELEASING.md). No ejecutar `git init` si el repositorio existe. No usar `git add .`; revisar y añadir rutas explícitas únicamente con autorización. No crear commits, cambiar ramas, configurar remotos ni publicar sin autorización aplicable.

La rama de desarrollo prevista es `main`. El repositorio actual aún no tiene commits; la transición inicial debe preservar `ai/setup-autonomous-environment`. No cambiar de rama hasta que el usuario apruebe el procedimiento después de revisar los archivos preparados.

Conservar los once perfiles `.codex/agents/*.toml`; excluir `.codex/config.toml` local y `.ai-local/`. `pubspec.lock` debe versionarse cuando exista la aplicación Flutter. Antes de preparar el primer commit, revisar lista exacta, diff, archivos ignorados, secretos y `git diff --check`. Una búsqueda automática de secretos no garantiza que no haya credenciales.

El commit inicial previsto para F0.2 es `chore(repo): preparar base inicial de desarrollo (F0.2)`. Este mensaje no autoriza crear el commit. No se modifica la configuración global de identidad de Git.

## Fallos esperados

- Sin FTS5 o corpus excesivo: error explícito; usar rg y reducir corpus justificadamente.
- Sin Git, con staged/cambios previos o rutas sensibles: runner bloqueado antes de invocar modelo.
- Podman no usable desde el sandbox: ejecutar diagnóstico autorizado en el anfitrión; nunca sustituirlo por permisos irrestrictos.
- Sin imagen/proveedor: conservar bloqueo, continuar documentación y pruebas locales.
- Timeout, salida excesiva o pruebas fallidas: detener contenedor propio, no aplicar archivos, revisar reporte local.
- Diagnóstico global de Codex: registrar observación; no reparar bases, auth o configuración personal fuera del alcance.

## Informe de cada misión

Objetivo, alcance, archivos, decisiones, investigaciones, comprobaciones reales, fallos y pendientes, riesgos, commit/estado Git y métricas expuestas. Entrada/salida/caché no disponibles se registran como null; costes desconocidos no se calculan. Añadir siguiente paso y actualizar traspaso antes de cerrar.
