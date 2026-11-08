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

El plan original sitúa F0.1 antes de F0.2. F0.1/F0.3 están completas y F0.4–F0.6 siguen parciales. La autorización explícita del 2026-11-08 permitió iniciar y completar documentalmente F1.1/F1.2 sin cerrar F0 ni implementar funcionalidades. media_kit y el reproductor quedan fuera. No instalar paquetes del sistema ni modificar configuraciones globales.

### F1.1/F1.2 — 2026-11-08

El propietario proporcionó las 14 selecciones exactas de sección 3 y pidió conciliarlas. F1.2 quedó uno-a-uno en ADR-001–ADR-014; 13 análisis anteriores se conservaron como adicionales en `docs/adr/additional/`. F1.1 se amplió con seis comportamientos MVP citados en `PROJECT_PLAN.md`; FR-12/NFR-12 se conservan como candidatos no contados. Estado y aprobaciones pendientes: `PROGRESS.md`, `PROJECT_PLAN.md`, `TECH_DECISIONS.md`, `docs/requirements/F1.1-CORE-REQUIREMENTS.md` y `docs/adr/README.md`. No se agregó código ni dependencia. Esperar la aprobación formal de F1.1/selecciones pendientes y no avanzar a F1.3 en esta tarea.

### Avance F0.1–F0.6 (2026-11-08)

F0.1/F0.3 completas; F0.4–F0.6 parciales. Entorno Fedora 44 con Flutter 3.47.9/Dart 3.13.7 y GTK3/libsecret/libmpv disponibles; ver `docs/environment/F0.1-FEDORA.md`. README y siete documentos Markdown requeridos están enlazados; D3/LICENSE pendiente, no bloquea F0.3. `flutter analyze` exit 255 reproduce falla LSP en ruta con `í`; `dart analyze lib test` pasa. El arreglo upstream #191377 aún no está en la stable 3.47.9 observada. SDK beta 3.50.0-0.4.pre no se probó porque el bundle de 1.5 GB tardaría más de una hora según velocidad observada; se retiró el parcial, SDK global intacto. Spectacle verificó visualmente la ventana Wayland: evidencia `docs/perf/wayland-window-20261108.png`; el TSV no tiene latencia numérica de ventana. Medición release: 462 ms al primer frame rasterizado, RSS mediano 140096 KiB/145284 KiB a 5 s, CPU reposo 0.60%; entorno 7.5 GiB, no objetivo 4 GB. Sin reproducción ni prueba prolongada de fugas. Cambios concurrentes en AGENTS.md, perfiles .codex y docs/ai-system permanecen ajenos; no mezclarlos ni revertirlos. No iniciar Fase 1.
