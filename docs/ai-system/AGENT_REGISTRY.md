# Registro de agentes

El coordinador de la sesión es el orquestador; no se crea un proceso adicional para ese rol. Los 11 perfiles existentes se reutilizan y heredan modelo, razonamiento y permisos. No se fijan nombres de modelos cuya disponibilidad no se haya comprobado.

| Perfil | Responsabilidad y activación | Herramientas/alcance |
| --- | --- | --- |
| planificador | Objetivo amplio, prioridades, fases, aceptación. | Lectura y planificación; no código. |
| arquitecto | Módulos, contratos y compatibilidad; investigación técnica oficial. | Lectura, búsqueda; implementación solo si se asigna explícitamente. |
| ux_ui | Flujos, accesibilidad y diseño. | Lectura, especificación, archivos asignados. |
| frontend | Interfaz y estado del cliente. | Edición asignada, navegador y pruebas disponibles. |
| backend | API y lógica de negocio. | Edición asignada y pruebas. |
| datos | Persistencia, consultas y migraciones. | Edición asignada; sin migraciones destructivas no autorizadas. |
| qa | Reproducción, casos límite y regresiones. | Pruebas y evidencia; fixtures aislados. |
| auditor_codigo | Corrección y revisión independiente. | Solo lectura, hallazgos accionables. |
| seguridad | Permisos, entradas y exposición de datos. | Solo lectura y fuentes públicas; sin revelar secretos. |
| devops | Entorno, CI, aislamiento y compilación. | Herramientas autorizadas del proyecto; sin despliegue ni servicios persistentes implícitos. |
| documentacion | Memoria, guías, ADR y traspaso. | Edición de documentación asignada y verificación. |

El rol funcional investigador se cubre con arquitecto o seguridad para sus ámbitos y con el coordinador para búsquedas pequeñas. Implementador se asigna a frontend/backend/datos/devops según archivos; tester corresponde a qa y auditor a auditor_codigo/seguridad. No duplicar perfiles con nombres nuevos para las mismas funciones.

## Contrato de delegación

Activación automática según esta tabla, sin pedir confirmación para delegar. Cada encargo entrega objetivo, contexto mínimo autosuficiente, archivos de propiedad exclusiva, restricciones y verificación. No reenviar el historial completo cuando basta un resumen y referencias. Los especialistas no subdelegan y no revierten cambios ajenos. Auditor e implementador deben tener tareas distintas.

Concurrencia configurada: un subagente; el límite administrado de la sesión puede ser diferente y nunca se supera. Las tres auditorías iniciales fueron paralelas antes de conocer la presión de RAM; el trabajo posterior de archivos independientes usó las plazas de esa sesión ya iniciada. En sesiones nuevas se aplica la configuración conservadora. Si la RAM disponible es menor a 1 GiB, no añadir procesos pesados: tareas secuenciales y registrar bloqueo de compilaciones grandes.

El coordinador revisa diff, evidencia y comprobaciones antes de integrar. No declarar pruebas verdes a partir de documentación histórica ni de un doble de prueba. La carga de perfiles está comprobada en esta sesión porque sus 11 nombres aparecen como tipos disponibles; no significa que estén todos activos ni que trabajen sin una misión.
