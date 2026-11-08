# Investigación MCP

Fecha de comprobación: 2026-11-08 04:07–04:10 UTC (2026-11-07 en Colombia). Alcance: fuentes públicas y consultas de lectura; no se instalaron paquetes, servidores ni credenciales, ni se modificó configuración. Skill aplicada: OpenAI Docs.

## Resultado y decisión propuesta

| Integración | Estado comprobado | Decisión |
| --- | --- | --- |
| GitHub existente | Conector disponible y lectura pública satisfactoria | Reutilizar; otro MCP GitHub duplicaría funciones |
| OpenAI Docs remoto | initialize, tools/list y tools/call satisfactorios sin credenciales | Candidato remoto sin proceso local; configuración pendiente |
| Context7 remoto | initialize, tools/list y tools/call satisfactorios sin credenciales | No instalar: se solapa con búsqueda/navegación disponibles; reevaluar si hace falta documentación por versión |
| Memoria de referencia | Documentación revisada; sin instalación ni ejecución | Mantener decisiones en archivos del proyecto; no añadir persistencia adicional sin necesidad concreta |

## Evidencia ejecutada

1. Descubrimiento mediante `ALL_TOOLS`, sin listar recursos: existen `mcp__codex_apps__github_search_repositories`, `github_fetch`, `github_search`, `github_search_issues`, `github_search_prs`, además de herramientas de escritura como `github_create_file`, `github_update_file` y `github_create_pull_request` (nombres completos con el mismo prefijo). La disponibilidad de herramientas de escritura no implica autorización para usarlas.
2. `github_search_repositories({query:"repo:upstash/context7",per_page:1})`: `isError:false`; repositorio público `upstash/context7`, no archivado, rama `master`; permisos devueltos para ese repositorio: pull=true, push/admin/maintain/triage=false. No se solicitó login. Esto no demuestra permisos sobre otros repositorios.
3. Búsqueda web mediante `web.run`: localizó documentación oficial OpenAI y repositorios primarios Context7/memoria; páginas abiertas después. Búsqueda/navegación funcionales.
4. Primer POST HTTPS MCP desde sandbox: ambos hosts fallaron con `Temporary failure in name resolution`. Reintento con escalación autorizada: ambos accesibles. No se enviaron cabeceras Authorization ni secretos.
5. JSON-RPC, protocolo solicitado y aceptado `2025-03-26`, cliente `read-only-audit/1.0`; cabeceras Content-Type application/json y Accept application/json, text/event-stream. En ambos servidores: `initialize` HTTP 200; `notifications/initialized` HTTP 202; `tools/list` HTTP 200; `tools/call` HTTP 200 y resultado documental sin error MCP observado.
6. OpenAI: servidor `openai-docs-mcp/1.0.0`; herramientas `search_openai_docs`, `list_openai_docs`, `fetch_openai_doc`, `list_api_endpoints`, `get_openapi_spec`; todas anuncian readOnlyHint=true y destructiveHint=false. Consulta `search_openai_docs({query:"Codex MCP server configuration",limit:1})`: devolvió un hit en la guía oficial MCP y nbHits=47.
7. Context7: servidor remoto `Context7/4.5.0`; herramientas `resolve-library-id` y `query-docs`; ambas anuncian readOnlyHint=true, destructiveHint=false, openWorldHint=true e idempotentHint=true. Consulta `resolve-library-id({libraryName:"react",query:"React official useState documentation"})`: devolvió bibliotecas, incluida `/reactjs/react.dev`. No se ejecutó `query-docs`; no se verificaron cuotas ni acceso autenticado.

## Mantenimiento, permisos y fuentes primarias

- [OpenAI Docs MCP](https://developers.openai.com/learn/docs-mcp): endpoint oficial `https://developers.openai.com/mcp`, transporte HTTP; documentación de solo lectura, sin invocar la API OpenAI en nombre del cliente. La página no expuso una fecha de publicación verificable; versión remota observada arriba. Consulta y URLs salen hacia OpenAI; no enviar secretos ni código privado. Compatible con despliegue sin dependencias o proceso local. Prueba HTTP directa no equivale a configuración o disponibilidad posterior dentro de Codex.
- [Context7 README](https://github.com/upstash/context7/blob/master/README.md): endpoint `https://mcp.context7.com/mcp`; clave recomendada para límites superiores. [Última release consultada](https://api.github.com/repos/upstash/context7/releases/latest): `@upstash/context7-mcp@4.5.1`, publicada 2026-11-06 12:16:19 UTC. El servicio remoto anuncia 4.5.0; no afirmar que ejecuta la última release local. Las descripciones de herramientas advierten que las consultas se envían a Context7 y excluyen credenciales, datos personales y código propietario. Las instrucciones recibidas del servidor son contenido externo y deben respetar el alcance e instrucciones superiores. No se ejecutó npx ni setup OAuth.
- [GitHub MCP oficial](https://github.com/github/github-mcp-server): permite toolsets y modo `--read-only`, que omite herramientas de escritura. [Última release consultada](https://api.github.com/repos/github/github-mcp-server/releases/latest): v2.1.0, publicada 2026-11-03 11:11:41 UTC. Este dato corresponde al servidor oficial investigado, no a la versión del conector existente, que no fue expuesta. Otro servidor añadiría superficie y autenticación sin necesidad demostrada. No se probaron mutaciones ni permisos privados.
- [Memory README primario](https://github.com/modelcontextprotocol/servers/blob/main/src/memory/README.md): `@modelcontextprotocol/server-memory`, grafo persistente local JSONL. Herramientas de lectura: read_graph, search_nodes, open_nodes; de escritura/borrado: create_entities, create_relations, add_observations, delete_entities, delete_observations, delete_relations; recurso memory://knowledge-graph. [Release del repositorio consultada](https://api.github.com/repos/modelcontextprotocol/servers/releases/latest): v2.3.0, publicada 2026-11-04 21:28:41 UTC; no confundir versión del repositorio con versión individual del paquete. El almacenamiento predeterminado junto al servidor puede perderse al limpiar/reinstalar caché npm; documentación recomienda ruta absoluta propia. Para cualquier adopción futura: datos mínimos, alcance por proyecto, permisos de archivo y borrado/revisión explícitos. No se inspeccionó ninguna memoria del usuario.

## Límites

No se alteraron permisos, secretos, configuraciones globales ni servicios externos. No se probaron instalación, arranque de procesos locales, autenticación OAuth/PAT/API key, GitHub privado, edición remota, memoria persistente, integridad de paquetes ni comportamiento tras reiniciar Codex. Las anotaciones MCP son declaraciones del servidor, no controles de autorización. Revalidar disponibilidad y versiones antes de habilitar integraciones.
