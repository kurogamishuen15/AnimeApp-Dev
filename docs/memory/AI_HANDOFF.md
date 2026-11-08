# Transferencia a otra IA

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Herramientas, docs y resultados reproducibles

## Contexto mínimo
Regla permanente: lee, busca e inspecciona solo esta raíz y sus subcarpetas. No explores Imágenes ni otras carpetas. No sigas enlaces fuera del proyecto. Si falta material fuera de aquí, documenta el bloqueo y pide que se coloque dentro del proyecto.

Trabajas solo en esta carpeta PROYECTO ANIME dentro de Vídeos. El usuario autoriza infraestructura de IA, no funciones de AnimeApp. No hay código de producto. No acceder a otro repositorio ni configuraciones personales.

## Cómo continuar
Leer AGENTS.md, PROJECT_STATE.md y FINAL_REPORT.md; buscar memoria con tools/ai/memory.py. Python stdlib, FTS5, fuentes Markdown, caché local ignorada. Ver MODULE_INDEX.md y DECISIONS.md.

## Comandos y riesgos
python3 tools/ai/memory.py check
python3 -m unittest discover -s tests/ai -v
python3 tools/ai/autonomy.py doctor

Los tests no acreditan una ejecución de modelo nocturna. Revisar estado Git, imagen/broker y alcance antes de ejecutar. No publicar ni hacer push.

## Próxima tarea
F0.2 se completó: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, `main` activa y subida a `origin` privado; se conservó `ai/setup-autonomous-environment` en el commit inicial. `AnimeApp-Dev` es privado y el público `AnimeApp` continúa vacío. La clonación limpia, las 40 pruebas de IA y la verificación de memoria pasaron. Identidad de Git configurada solo localmente; no copiar sus datos a documentos. `.ai-local/` y `.codex/config.toml` están excluidos. Los informes `ENVIRONMENT_AUDIT.md` y `MCP_RESEARCH.md` son internos: el proceso público exige seleccionar archivos expresamente y excluye esos informes salvo aprobación de versiones revisadas y depuradas.

El plan original sitúa F0.1 antes de F0.2; F0.1–F0.6 ya se revisaron bajo autorización expresa, sin avanzar a Fase 1. media_kit y el reproductor quedan fuera. No instalar paquetes del sistema ni modificar configuraciones globales.

### Avance F0.1–F0.6 (2026-11-08)

F0.1/F0.3 completas; F0.4–F0.6 parciales. Entorno Fedora 44 con Flutter 3.47.9/Dart 3.13.7 y GTK3/libsecret/libmpv disponibles; ver `docs/environment/F0.1-FEDORA.md`. README y los siete documentos Markdown requeridos tienen links revisados; D3/LICENSE sigue pendiente, no bloquea F0.3. `flutter analyze` exit 255 reproduce la falla LSP en la ruta con `í`, mientras `dart analyze lib test` pasa; ver `TESTING.md` y referencias upstream. App compila, `flutter run` inició proceso pero la visibilidad no se verificó; Wayland hace que herramientas X11 no observen superficies. Medición release final: 462 ms al primer frame rasterizado, RSS mediano 140096 KiB y a 5 s 145284 KiB, CPU reposo 0.60% de un núcleo; 7.5 GiB RAM (no el equipo objetivo 4 GB). Ver `PROGRESS.md`, `docs/perf/README.md` y reporte `docs/perf/measure-20261108T133341Z-15982.tsv`. Sin reproducción ni prueba prolongada de fugas. Cambios concurrentes en AGENTS.md, perfiles .codex y docs/ai-system permanecen ajenos; no mezclarlos ni revertirlos. No Fase 1 hasta resolver pendientes y completar commits autorizados.
