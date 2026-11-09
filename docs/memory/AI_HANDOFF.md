# Transferencia a otra IA

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-08
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Herramientas, docs y resultados reproducibles

## Contexto mínimo
Regla permanente: lee, busca e inspecciona solo esta raíz y sus subcarpetas. No explores Imágenes ni otras carpetas. No sigas enlaces fuera del proyecto. Si falta material fuera de aquí, documenta el bloqueo y pide que se coloque dentro del proyecto.

Trabajas solo en esta carpeta PROYECTO ANIME dentro de Vídeos. El alcance inicial de infraestructura IA no autoriza funciones del producto; la autorización posterior permitió únicamente documentación F1.1/F1.2. No implementar funcionalidades sin nueva instrucción. No acceder a otro repositorio ni configuraciones personales.

## Cómo continuar
Leer AGENTS.md, PROJECT_STATE.md y FINAL_REPORT.md; buscar memoria con tools/ai/memory.py. Python stdlib, FTS5, fuentes Markdown, caché local ignorada. Ver MODULE_INDEX.md y DECISIONS.md.

## Comandos y riesgos
python3 tools/ai/memory.py check
python3 -m unittest discover -s tests/ai -v
python3 tools/ai/autonomy.py doctor

Los tests no acreditan una ejecución de modelo nocturna. Revisar estado Git, imagen/broker y alcance antes de ejecutar. No publicar ni hacer push.

## Próxima tarea
F0.2 se completó: commit inicial `84efbfb4a3468170acac27a9f39fef58746e1b5a`, `main` activa y subida a `origin` privado; se conservó `ai/setup-autonomous-environment` en el commit inicial. `AnimeApp-Dev` es privado y el público `AnimeApp` continúa vacío. La clonación limpia, las 40 pruebas de IA y la verificación de memoria pasaron. Identidad de Git configurada solo localmente; no copiar sus datos a documentos. `.ai-local/` y `.codex/config.toml` están excluidos. Los informes `ENVIRONMENT_AUDIT.md` y `MCP_RESEARCH.md` son internos: el proceso público exige seleccionar archivos expresamente y excluye esos informes salvo aprobación de versiones revisadas y depuradas.

El plan original sitúa F0.1 antes de F0.2. F0.1/F0.3 están completas y F0.4–F0.6 siguen parciales. La autorización explícita del 2026-11-08 permitió completar documentalmente F1.1/F1.2 sin cerrar F0 ni implementar funcionalidades. media_kit está aprobado solo como motor de referencia para F2; no se instala ni implementa en F1. No instalar paquetes del sistema ni modificar configuraciones globales.

### F1.1–F1.3 — 2026-11-08

El propietario aprobó formalmente F1.1 (18 FR + 13 NFR; FR-11 con semántica por campo pendiente y sin reglas inventadas; metas de rendimiento preliminares), las 14 selecciones ADR-001–ADR-014 como arquitectura de referencia y F1.3 (núcleo compartido, Fedora/Linux primero, adaptadores progresivos por necesidad). F1.1–F1.3 están completadas documentalmente; ver `PROGRESS.md`, `ARCHITECTURE.md`, ADR-015 y sesión `2026-11-08-f1-3-architecture.md`. Las integraciones mantienen validaciones por fase; ADR-A01–A13 siguen como documentos complementarios, sin aprobación automática. No se agregó código ni dependencia. F1.4 sigue pendiente; implementará solo la estructura modular mínima Linux y contratos compartidos justificados, sin código futuro Android/TV/Windows. Los tres commits documentales F1.1/F1.2 están en AnimeApp-Dev privado; F1.3 tiene documentación local pendiente de registrar. Cambios concurrentes en `AGENTS.md`, `.codex/agents/` y `docs/ai-system/` permanecen ajenos y deben preservarse.
### Avance F0.1–F0.6 (2026-11-08)

F0.1/F0.3 completas; F0.4–F0.6 parciales. Entorno Fedora 44 con Flutter 3.47.9/Dart 3.13.7 y GTK3/libsecret/libmpv disponibles; ver `docs/environment/F0.1-FEDORA.md`. README y siete documentos Markdown requeridos están enlazados; D3/LICENSE pendiente, no bloquea F0.3. `flutter analyze` exit 255 reproduce falla LSP en ruta con `í`; `dart analyze lib test` pasa. El arreglo upstream #191377 aún no está en la stable 3.47.9 observada. SDK beta 3.50.0-0.4.pre no se probó porque el bundle de 1.5 GB tardaría más de una hora según velocidad observada; se retiró el parcial, SDK global intacto. Spectacle verificó visualmente la ventana Wayland: evidencia `docs/perf/wayland-window-20261108.png`; el TSV no tiene latencia numérica de ventana. Medición release: 462 ms al primer frame rasterizado, RSS mediano 140096 KiB/145284 KiB a 5 s, CPU reposo 0.60%; entorno 7.5 GiB, no objetivo 4 GB. Sin reproducción ni prueba prolongada de fugas. Cambios concurrentes en AGENTS.md, perfiles .codex y docs/ai-system permanecen ajenos; no mezclarlos ni revertirlos. No iniciar Fase 1.
