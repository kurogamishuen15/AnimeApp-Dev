# OC-03.1 · Auditoría del transporte remoto

La reproducción de Wikimedia se verificó en Fedora. La aceptación del pack
de fuentes completo permanece pendiente. El
[checkpoint de transporte](../missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md)
registra versiones, materiales primarios consultados el 16 de noviembre,
programas ejecutados y evidencia visual.

## Alcance

Revisión independiente de los cambios en `PlaybackRequestHeaders`,
`public_playback_http.dart`, `wikimedia_anime_provider.dart`,
`playback_providers_module.dart`, registro de hosts y efectos observables
en media_kit 1.2.6. La comprobación del motor se hizo con un servidor
HTTP local y con Wikimedia en red. Se preservaron los transports históricos
para los demás proveedores.

| ID | Nivel | Evidencia y consecuencia | Estado |
|---|---|---|---|
| UA-01 | P1 | La cadena existente no enviaba UA por medio. El servidor de captura observó `libmpv`. Para el mismo 480p, ffprobe con `libmpv` devolvió 429 y el UA de Kongroo leyó VP9/Opus. | Corregido en `playback_source.dart` y `wikimedia_anime_provider.dart`. El test verifica los headers efectivos en apertura, reapertura y siguiente fuente. Fedora mostró dos fotogramas y seek de 20 s. |
| UA-02 | P2 | Si se contabiliza cada rechazo local del cooldown como error de red, consultas repetidas pueden abrir el breaker 60 s y prolongar el plazo informado. | Corregido en `playback_provider_contract.dart`. Las pruebas ejercitaron Retry-After en segundos y fecha, además de rechazo sin repetir la petición. |
| UA-03 | P2 | Una respuesta chunked que supere el prefijo de diagnóstico puede mantener la suscripción upstream de Dio tras liberar el cupo. | `public_playback_http.dart` cancela el token en finally, incluso al truncar el cuerpo. Contraste con implementación Dio 5.11.1. Falta una prueba con un servidor hostil o lento que nunca cierre el cuerpo. |
| UA-04 | P2 | La referencia anterior describía el repositorio del contacto UA como privado. | Se comprobó acceso sin credenciales a `AnimeApp-Dev/issues`. Respondió HTTP 200 y título de Issues del proyecto. |
| UA-05 | P1 | El motor recibe el WebM directamente y sus conexiones Range internas pueden producir 429 independientemente del estado de Dio. | Abierto. La espera del API es verificable. Falta entregar el Retry-After del CDN al coordinador y comprobar un presupuesto global de conexiones bajo cambios y seeks. |
| UA-06 | P1 | Los dos CDN experimentales respondieron 403 y 500 a HEAD tras resolver sus medios. | Abierto. Mantener estado experimental. Falta identificar rutas permitidas y verificar un segundo host con cuadros y seek. |

## Regresión

La suite Flutter final aprobó 337 y omitió 11 pruebas optativas. La prueba
nativa adicional de cabeceras pasó. La tanda de contrato y proveedores con
sondas activadas aprobó 16, incluidos ambos descubrimientos reales. El
análisis estático y el comprobador de imports finalizaron correctamente.
Las capturas y logs están dentro de la raíz Git en `.ai-local/oc03-ua/`.
La prueba gráfica se ejecutó con la ventana del lanzador de diagnóstico
y las mismas clases de composición, decodificación y presentación del producto.
Faltan segunda plataforma, audición, recorrido nuevo de la ficha y progreso
persistido con el remoto. La selección de alternativa ante un fallo fue
comprobada con dobles de transporte.
