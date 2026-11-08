# Registro de MCP e investigación

Fecha: 2026-11-07. Evidencia completa: [MCP_RESEARCH.md](MCP_RESEARCH.md). Solo se selecciona un MCP adicional remoto de lectura; no se instala npm, base vectorial ni servidor residente.

| Capacidad | Selección | Prueba y límite |
| --- | --- | --- |
| OpenAI/Codex oficial | `.codex/config.toml`: `openai_docs`, HTTP oficial | initialize, tools/list, search_openai_docs reales satisfactorios; se permiten solo búsqueda y fetch. Aplicación efectiva de config se verifica aparte; clientes ya abiertos pueden necesitar recargar. |
| GitHub público | Conector existente | Consulta pública real satisfactoria, sin escribir ni solicitar credenciales. Versión interna no expuesta. No añadir otro servidor GitHub. |
| Web general | Herramienta de navegación de esta sesión | Búsqueda y apertura reales; en CLI depende de capacidades/proveedor. No garantizar portabilidad del conector desktop. |
| Context7 | No habilitado | Servicio remoto respondió; se solapa con navegación. Reconsiderar para documentación de bibliotecas/versiones cuando haya una necesidad concreta. |
| Memoria | CLI local, Markdown + SQLite | Pruebas y evaluación; no requiere MCP, red ni suscripción. Server-memory solo investigado, no instalado ni probado. |
| node_repl personal | Preexistente, sin cambios | Fuera de configuración compartida y de esta misión tras delimitar alcance; no copiar credenciales ni configuración personal. |

OpenAI Docs remoto observó `openai-docs-mcp/1.0.0`; no se puede fijar el binario de un servicio HTTP administrado. Se fija URL oficial y allowlist de dos herramientas; revalidar catálogo y compatibilidad. Las anotaciones readOnlyHint no son una barrera de seguridad por sí solas. No enviar código privado ni secretos en consultas.

El servidor no es required: una caída no debe impedir trabajo local. No deshabilitar plugins o herramientas globales ajenas; no existe un permiso del proyecto para retirar el catálogo de esta sesión. La allowlist limita únicamente este servidor compartido.

Protocolo: memoria → documentación oficial → issues/repositorios → comparación → licencia/compatibilidad → prueba → decisión documentada. Resúmenes breves con URL, versión y fecha; no copiar código externo sin licencia verificada. En esta implementación no se copió código de terceros.
