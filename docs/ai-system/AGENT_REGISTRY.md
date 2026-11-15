# Registro de agentes

El coordinador de la sesión es el orquestador; no se crea un proceso adicional para ese rol. Hay 21 perfiles: se conservan los 11 iniciales y se añaden 10 especialistas delimitados.

Los 21 perfiles omiten `model` y `model_reasoning_effort`; la configuración local tampoco fija valores predeterminados. Según la documentación oficial de Codex, estos valores se resuelven desde la solicitud de inicio, luego los valores predeterminados de `[agents]` y finalmente el agente padre. Así los perfiles heredan modelo y esfuerzo del chat principal. Fuente: [subagentes y agentes personalizados](https://learn.chatgpt.com/docs/agent-configuration/subagents).

| Perfil | Responsabilidad y activación | Herramientas/alcance |
| --- | --- | --- |
| planificador | Objetivo amplio, prioridades, fases, aceptación. | Lectura y planificación; no código. |
| arquitecto | Módulos, contratos y compatibilidad; investigación técnica oficial. | Lectura, búsqueda; implementación solo si se asigna explícitamente. |
| ux_ui | Flujos, accesibilidad y diseño. | Lectura, especificación, archivos asignados. |
| frontend | Interfaz y estado del cliente. | Edición asignada, navegador y pruebas disponibles. |
| backend | API y lógica de negocio. | Edición asignada y pruebas. |
| datos | Persistencia, consultas y migraciones. | Edición asignada; sin migraciones destructivas no autorizadas. |
| qa | Reproducción, casos límite y regresiones. | Pruebas y evidencia; fixtures aislados. |
| auditor_codigo | Corrección y revisión independiente. | Solo lectura, hallazgos accionables; aplica el protocolo KONGROO en auditorías sustanciales. |
| seguridad | Permisos, entradas y exposición de datos. | Solo lectura y fuentes públicas; sin revelar secretos. |
| devops | Entorno, CI, aislamiento y compilación. | Herramientas autorizadas del proyecto; sin despliegue ni servicios persistentes implícitos. |
| documentacion | Memoria, guías, ADR y traspaso. | Edición de documentación asignada y verificación. |
| monitoreo | Resúmenes puntuales de CI, métricas o informes. | Solo la instantánea solicitada; no permanece observando ni crea timers. |
| investigador | Hechos que cambian, documentación y fuentes primarias. | Memoria primero; fuentes y citas; separa inferencia. |
| auditor_dependencias | Versiones, compatibilidad, licencias y cadena de suministro. | Solo lectura; no instala ni actualiza. |
| auditor_rendimiento | CPU, RAM, latencia, reconstrucciones y liberación de recursos. | Evidencia medida; revisión acotada y de solo lectura. |
| auditor_arquitectura | Límites de módulos, dependencias y cumplimiento de ADRs. | Revisión independiente, solo lectura. |
| auditor_contratos | Contratos internos/externos y compatibilidad entre componentes. | Interfaces, errores y versionado; solo lectura. |
| auditor_accesibilidad | Foco, teclado/D-pad, semántica y barreras de interfaz. | Rutas de reproducción y criterio; no sustituye pruebas manuales. |
| auditor_release | Empaquetado, licencias, notices y checklist de entrega. | Solo lectura; no etiqueta ni publica. |
| diagnostico_logs | Clasificación y reproducción de fallos a partir de logs. | Fragmentos mínimos redactados; no volcar trazas ni salir del proyecto. |
| gestor_cola | Ordenar solicitudes, dependencias, prioridades y aceptación. | Organiza y detecta duplicados; no inicia tareas ni edita archivos. |

El rol funcional investigador se cubre con arquitecto o seguridad para sus ámbitos y con el coordinador para búsquedas pequeñas. Implementador se asigna a frontend/backend/datos/devops según archivos; tester corresponde a qa y auditor a auditor_codigo/seguridad. No duplicar perfiles con nombres nuevos para las mismas funciones.

## Contrato de delegación

Activación automática según esta tabla, sin pedir confirmación para delegar. Cada encargo entrega objetivo, contexto mínimo autosuficiente, archivos de propiedad exclusiva, restricciones y verificación. No reenviar el historial completo cuando basta un resumen y referencias. Los especialistas no subdelegan y no revierten cambios ajenos. Auditor e implementador deben tener tareas distintas.

Concurrencia configurada: un subagente; el límite administrado de la sesión puede ser diferente y nunca se supera. Los perfiles aparecen en sesiones nuevas tras cargar la configuración del proyecto; esta edición no activa veinte procesos. Si la RAM disponible es menor a 1 GiB, no añadir procesos pesados: tareas secuenciales y registrar bloqueo de compilaciones grandes.

El coordinador revisa diff, evidencia y comprobaciones antes de integrar. No declarar pruebas verdes a partir de documentación histórica ni de un doble de prueba. Los 21 perfiles están definidos en `.codex/agents/`; su disponibilidad como perfiles no significa que estén ejecutándose ni que todos aparezcan en el historial. La vista de subagentes muestra ejecuciones con una misión, no el catálogo completo.
