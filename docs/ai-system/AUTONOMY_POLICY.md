# Política de autonomía

## Alcance autorizado
La raíz y sus subcarpetas son el único ámbito legible y escribible. No inspeccionar ni listar Imágenes, Documentos, Descargas, el directorio padre, otras carpetas de proyectos, el hogar ni unidades externas. No seguir enlaces simbólicos fuera de la raíz. Si una dependencia está fuera, bloquearla y pedir que se coloque dentro; no buscarla.


Únicamente esta carpeta de Vídeos y fixtures temporales de pruebas. La misión configura el entorno IA, no funcionalidades de AnimeApp. No usar ni modificar otro repositorio. No escribir configuración personal ni reparar bases internas de Codex fuera del alcance. La investigación pública no autoriza transmitir archivos privados.

Se permite leer documentación/código autorizado, planificar, decidir dentro del alcance, editar infraestructura, ejecutar análisis y pruebas, actualizar memoria y crear commits locales en una rama de trabajo. No se permite push ni publicación durante esta instalación.

Requieren autorización específica: borrados masivos/destructivos, cambios de Fedora, permisos globales, acceso a documentos personales, lectura o transmisión de credenciales, servicios persistentes, releases y operaciones irreversibles. La ausencia del usuario nunca equivale a aprobar. Registrar bloqueos y continuar tareas independientes seguras.

## Ejecutor implementado y límites reales

`tools/ai/autonomy.py` requiere Git comprobado, sin cambios tracked ni staged, misión JSON, Podman rootless e imagen local fijada por SHA256. No descarga imágenes ni ejecuta código de modelo directamente en el anfitrión. No se usan permisos irrestrictos, socket de Podman, hogar ni archivos auth del usuario.

El estado compartido usa un especialista por vez. El contenedor limita CPU, RAM, PIDs, tiempo, tamaño por archivo y espacio temporal. Contexto de lectura explícito; solo archivos permitidos existentes y rastreados se montan escribibles. Se rechazan rutas sensibles, symlinks, traversal, archivos nuevos y exceso de presupuestos. Esta primera versión prioriza correcciones pequeñas; no soporta scaffolding arbitrario, grandes builds ni instalación automática de dependencias. Las herramientas deben venir en una imagen verificada.

El workspace es una copia con montaje base de solo lectura; se montan individualmente hasta 16 archivos permitidos, con 4 MiB máximo por archivo. Contexto explícito hasta 1024 archivos y 64 MiB; salida stdout hasta 1 MiB y stderr hasta 64 KiB. Las validaciones posteriores se ejecutan sin red. No integrar cambios si falla el modelo, falta JSONL íntegro/turn.completed, una validación falla, hay cambios fuera de lista o edición concurrente. La integración de varios archivos no es una transacción atómica ante errores de disco: revisión Git y recuperación son necesarias.

## Proveedor, red y estado de preparación

La misión usa red none por defecto y se bloquea si requiere proveedor remoto. bridge exige declaración broker_prepared y una imagen etiquetada external-broker; estas declaraciones no demuestran autenticación ni restringen destinos por sí solas. run comprueba doctor dentro de la imagen y exige ejecución real satisfactoria antes de integrar. El broker debe aprovisionarse por un procedimiento autorizado que no hornee secretos en la imagen ni monte el hogar. No hay broker implementado por esta misión y no se afirma que esté preparado.

plan produce código 2 y execution_ready:false incluso si el preflight pasa: no es una certificación del proveedor. doctor inspecciona ayudas locales; no equivale al diagnóstico de proveedor del contenedor. La ausencia de imagen/proveedor es un bloqueo previsto, no un motivo para ampliar permisos.

## Ciclo y reparación

Recuperar memoria → concretar objetivo/aceptación → investigar → implementar → validar → revisar → documentar → actualizar memoria → revisar diff → commit local autorizado → informe. Una ejecución del runner hace un intento efectivo; admite max_attempts hasta 3 para compatibilidad del esquema, pero no reintenta automáticamente. Correcciones posteriores requieren evidencia de progreso y una ejecución explícita; detenerse ante repetición sin avance.

El runner no crea commits ni ramas por sí mismo; commit:true se rechaza. El coordinador sí puede realizar commits locales conforme al runbook y autorización de esta misión, tras revisar archivos exactos. Un reporte completed del runner significa validación técnica y aplicación de archivos, no aceptación funcional ni auditoría independiente.

## Persistencia

No se instalan servicios, cron, timers ni arranque automático. tmux puede mantener una sesión al cerrar el cliente mientras el servidor siga activo; no garantiza reinicio, suspensión ni alimentación. systemd --user se evaluó pero no se configura por no haber ejecutor completo ni autorización para un servicio persistente. Recuperación por memoria y nueva misión explícita; no reanudar automáticamente trabajo tras un reinicio.

Estado de aceptación real en EVALUATION.md y FINAL_REPORT.md. No dejar trabajo desatendido hasta superar una prueba con la imagen y proveedor reales.
