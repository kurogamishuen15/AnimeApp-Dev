# Adaptador de OpenSubtitles F2.8

## Propósito y límites

`OpenSubtitlesClient` adapta el contrato de catálogo de subtítulos externos al
API v1 de OpenSubtitles.com. Convierte respuestas HTTP en modelos domain,
descarga un subtítulo permitido a almacenamiento local y solo devuelve a
application un URI `file:`. No conoce Flutter, libmpv, `Player` ni el widget; no
interpreta ni persiste progreso. El fixture HTTP no requiere red ni credenciales.

## Archivos y contratos

| Archivo | Responsabilidad | Dependencias | Contrato observable |
|---|---|---|---|
| `opensubtitles_client.dart` | Consulta, normalización, errores, descarga limitada, validación y almacenamiento local | Dio 5.11.1, path_provider, `ExternalSubtitleCatalog` | `search(query)` y `download(candidate)` devuelven resultados tipados; nunca exponen el enlace temporal |
| `README.md` | Límites, seguridad, lifecycle, pruebas y extensiones | API oficial v1 | Guía operativa de esta capa |

El contrato domain vive en `domain/player/subtitles/external_subtitle_catalog.dart`.
Application vive en `application/player/external_subtitles/`; la UI de prueba
está en `app/player/external_subtitle_search_panel.dart`. La dependencia
apunta desde la composición del spike a domain y a este adaptador; domain no
importa Dio ni tipos de proveedor.

## Credenciales y lifecycle

`OpenSubtitlesSecret` es una función inyectada que devuelve la API key. El
entrypoint lee `OPENSUBTITLES_API_KEY` del entorno al iniciar la llamada; el
valor no está en el repositorio, archivos de configuración ni logs. Se puede
inyectar un bearer por separado. La solicitud `POST /download` lleva la API
key y, cuando se configura, bearer; la descarga del enlace temporal no recibe
ninguno de esos headers. Las pruebas usan placeholders que nunca salen del
adaptador fake.

El cliente cierra el `Dio` que construyó. El composition root pasa
`subtitleCatalog.close` a `SpikePlayerModule`; el módulo lo invoca después de
la limpieza del motor al cerrar y durante rollback de inicialización. Si se
inyecta un `Dio` en el constructor, su creador conserva la propiedad y debe
cerrarlo.

## Flujo HTTP

### Búsqueda

`search` forma `GET /api/v1/subtitles`, omite filtros vacíos, normaliza texto,
idiomas e IMDb ID, y estabiliza el orden de parámetros. Acepta búsqueda por
título, IMDb/TMDB, temporada/episodio, hash o `parent_imdb_id`; el panel actual
solo ofrece texto en inglés. Sigue hasta tres redirects de búsqueda únicamente
si conservan HTTPS, puerto 443, la ruta `/api/v1/subtitles` y uno de los hosts
oficiales `api.opensubtitles.com` o `vip-api.opensubtitles.com`. La API key no
se reenvía a un host externo. La respuesta `data[].attributes.files[]` produce
un candidato domain por cada archivo utilizable; los resultados multipart
conservan `cd_number` y muestran `Part x/y` en el panel. La coincidencia por
hash solo se marca si la API la declara.

### Descarga

`download` exige un `fileId` positivo y extensiones `srt`, `ass`, `ssa` o
`vtt`. Solicita `POST /api/v1/download`; la cuota puede consumirse al solicitar
el enlace, antes de bajar sus bytes. Valida que el enlace y cada redirect sean
HTTPS, puerto 443, host exacto `www.opensubtitles.com` y ruta `/download/`.
Los enlaces firmados no se guardan, pasan a UI ni se envían a libmpv.

Los bytes se leen con máximo configurable de 10 MiB, UTF-8 estricto, sin NUL y
con estructura mínima del formato. Si un body se descarta por redirect o error,
se cancela el `CancelToken` asociado. Se conserva `Retry-After` tanto en una
respuesta 429 de API como en el GET de bytes, sin reintentar automáticamente.
En Dio 5.11.1 cancelar solo el listener de `ResponseType.stream` no canceló el
stream fuente en la regresión local; el token sí produjo la cancelación
observable y quedó cubierto por test. El límite de tamaño aplica el mismo
mecanismo para interrumpir la descarga excedida.

El nombre local se genera con ID numérico y un token validado; el `file_name`
remoto no construye rutas. El token, el directorio y su proveedor son
inyectables para pruebas, pero producción usa un token aleatorio y
Application Support. Se crea `.part` de forma exclusiva y solo se elimina si
esta transferencia consiguió crearlo; después se renombra al archivo final.
No se extraen archivos ni se ejecuta contenido. El adaptador no deduplica ni
limpia automáticamente archivos descargados; quedan en el directorio de
soporte de la app.

## Errores y cuota

El resultado tipado distingue falta de clave, 401/403/404, límite de requests,
cuota de descarga agotada cuando la API lo identifica, timeout/red, respuesta
malformada, redirect API no permitido, formato/URL no permitidos,
tamaño/contenido inválido, falla de almacenamiento y bloqueo por hardsub.
`remaining` y `reset_time_utc` se conservan cuando están presentes.
`Retry-After` acepta segundos o fecha HTTP tanto en la llamada de API como en
la descarga; no se ejecutan reintentos automáticos y no se fija una cuota
numérica.

El service convierte excepciones lanzadas por el puerto en un fallo tipado y
rechaza cualquier resultado de descarga cuyo URI no sea local. Si hardsub está
confirmado, bloquea antes de solicitar el enlace y consumir cuota; estado
desconocido permite continuar con aviso. La selección/carga final pasa por el
coordinator, que serializa la acción, y el engine vuelve a verificar formato,
archivo regular y política.

## Pruebas y limitaciones

Desde `app/` y con la toolchain local seleccionada:

```bash
flutter test --no-pub test/data/opensubtitles/opensubtitles_client_test.dart
flutter test --no-pub test/application/external_subtitle_service_test.dart
flutter test --no-pub test/player/external_subtitle_search_panel_test.dart
flutter test --no-pub test/player/media_kit_spike_integration_test.dart --plain-name 'real libmpv loads an OpenSubtitles fixture downloaded to local storage'
```

Los tests fake cubren query/candidate, falta de clave, respuesta vacía o
malformada, 401/403/429/cuota, `Retry-After` en búsqueda y descarga, redirects
permitidos/rechazados, multipart, descarga SRT, aislamiento de headers, URL
hostil, formato inválido, cancelación del body, límite de bytes, contenido
corrupto, colisión `.part` y fallo del proveedor de almacenamiento. Application
cubre bloqueo antes de cuota, solo URI local y excepciones del catálogo; widget
cubre búsqueda, selección/carga, resultado visible, consulta vacía, límite del
campo y rechazo de una búsqueda enviada mientras otra sigue pendiente. El test
libmpv conecta el cliente HTTP fake, storage temporal, service, coordinator y
motor nativo real, y comprueba que el archivo descargado se vuelve pista
externa seleccionada. No comprueba una respuesta del servicio real ni
renderizado gráfico del texto.

No se configuró una API key o bearer real. No se hizo solicitud live ni se
consumió cuota real. El panel ofrece búsqueda por título en inglés; todavía no
elige metadatos IMDb/TMDB/hash desde catálogo. No se verificó si la cuenta real
del propietario tiene cuota, autorización o un redirect adicional de CDN.

## Fuentes oficiales

Consultadas el 2026-11-11: [referencia API OpenSubtitles v1](https://ai.opensubtitles.com/api-docs).
La referencia enumera `GET /subtitles` y `POST /download`, explica que la
acción que solicita el enlace cuenta para la cuota, describe los campos de
cuota y muestra enlaces `https://www.opensubtitles.com/download/...`. Esto
confirma el host usado por el ejemplo y no demuestra todos los posibles
redirects de cuentas o archivos reales.
