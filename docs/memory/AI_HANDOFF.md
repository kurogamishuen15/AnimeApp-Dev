# Transferencia a otra IA

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
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
Revisar el índice Git preparado para F0.2 y los resultados de `git diff --cached`. No ejecutar commit hasta aprobación explícita. La identidad Git autorizada está configurada solo localmente; sus datos no se copian a documentación. No hay remotos ni commits; conservar la rama `ai/setup-autonomous-environment` y no cambiar a `main`. `.ai-local/` y `.codex/config.toml` están excluidos. `docs/ai-system/ENVIRONMENT_AUDIT.md` y `MCP_RESEARCH.md` están autorizados solo para el repo privado; la publicación futura debe usar selección explícita de archivos y dejarlos fuera salvo aprobación de versiones depuradas. F0.1 sigue pendiente; no inicializar Flutter ni instalar paquetes.
