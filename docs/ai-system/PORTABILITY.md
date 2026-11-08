# Continuar con Claude, OpenCode u otra IA

Las fuentes de verdad son Markdown y código Python estándar, sin API exclusiva. Abrir la misma carpeta autorizada, leer AGENTS.md y docs/memory/PROJECT_STATE.md. Si el cliente no descubre AGENTS automáticamente, indicarle explícitamente que lo lea; no duplicar políticas en múltiples archivos que puedan contradecirse.

Generar `python3 tools/ai/memory.py handoff --max-chars 6000` y compartir esa salida y las referencias necesarias. Consultar estado Git y FINAL_REPORT; verificar afirmaciones con comandos y código. Las rutas son relativas al proyecto; el índice se reconstruye en cualquier equipo compatible.

Los perfiles TOML son específicos de Codex. Otro orquestador debe mapear el registro de agentes a sus propias herramientas, conservar responsabilidades y límites y heredar el modelo que tenga disponible. No se han probado CLI de Claude/OpenCode ni modelos gratuitos: compatibilidad de archivos no demuestra equivalencia de herramientas, capacidad o costes.

La búsqueda FTS5 funciona sin modelo ni suscripción. Si no hay FTS5, usar `rg -n "términos" docs/memory docs/ai-system` y consultar los índices manualmente. No instalar automáticamente un modelo local en un equipo con poca RAM. Puede evaluarse un proveedor gratuito en una misión posterior, con pruebas de calidad y licencia.

Para migrar, versionar memoria, herramientas y pruebas; no transferir .ai-local, auth, tokens ni configuración personal. Respaldos privados se gestionan por separado. Revalidar permisos y autenticación del cliente destino antes de una ejecución desatendida.
