# OC-04 — alternativas seguras ante HTTP 403

Fecha: 2026-11-17
Estado: alternativa de usuario implementada; el bloqueo de origen y el playback
interno siguen abiertos.
Alcance: investigar el HTTP 403 ya observado en Miruro, preparar una alternativa
compatible y comprobar que no se altera el reproductor.
Git: checkout con cambios concurrentes previos; no se preparó el índice, no hubo
commit ni push.

## Resumen

No existe una corrección genérica en el cliente para que una solicitud rechazada
por el servicio pase a estar autorizada. RFC 9110 define 403 como una respuesta
en la que el servidor entendió la solicitud y se niega a cumplirla; no revela el
motivo concreto. Cloudflare documenta causas posibles como reglas del origen,
WAF, IP y nivel de seguridad, pero la evidencia observada no identifica cuál
aplica a Miruro. La corrección del 403 de ese servicio requiere una ruta pública
autorizada o una aclaración del operador. No se repitió la llamada bloqueada.

Se dejó preparada una salida segura en Kongroo: AniList puede aportar enlaces
de episodios a páginas externas que la ficha muestra y permite copiar. Esos
enlaces no son medios directos y nunca se entregan a libmpv. También se probó
que el manager existente consulta otro provider si el primero falla; el fallback
solo funciona cuando el segundo provider está registrado y habilitado. Esto no
resolvió el 403 de Miruro ni verificó un provider alternativo real para AniList
100240; ese flujo sigue en **0 fuentes confirmadas**. Wikimedia conserva una
evidencia histórica opt-in de Namakura Gatana, que no valida este provider ni el
fallback.

## Alcance y entorno

- Repositorio: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Plataforma: Fedora Linux, sesión del agente; no se hizo interacción visual ni
  se probó una reproducción externa en la ventana de Kongroo.
- Flutter aislado: `3.50.0-0.4.pre`; Dart `3.14.0`. No se actualizó el SDK
  global ni se agregaron paquetes.
- Se revisaron el contrato de metadatos de ficha, la consulta y caché AniList,
  el widget de episodios, el mapeo de 403, el registro de providers, el manager,
  pruebas cercanas y sus README.
- El checkout ya contenía numerosos cambios locales y archivos sin seguimiento
  ajenos a esta entrega. Se conservaron; no se usó `git add`.

## Investigación externa

Fuentes consultadas el 2026-11-17:

1. [RFC 9110, sección 15.5.4](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.5.4): establece que 403 representa una negativa del servidor. No establece que cambiar cabeceras, cliente o ruta sea una solución autorizada.
2. [Documentación de Cloudflare sobre errores 403](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/4xx-client-error/error-403/): enumera políticas del origen, reglas WAF/IP y configuración de seguridad como causas posibles. No permite inferir la regla concreta aplicada a Miruro.
3. [AniList: `MediaStreamingEpisode`](https://github.com/AniList/docs/blob/master/docs/reference/object/mediastreamingepisode.md) y [AniList: `Media`](https://github.com/AniList/docs/blob/master/docs/reference/object/media.md): describen `streamingEpisodes` como enlaces de streaming legales en sitios externos, con campos como título, URL y sitio. Esta documentación describe enlaces de páginas externas, no un contrato de URL multimedia para libmpv.

### Alternativas consideradas

| Alternativa | Resultado | Límite |
| --- | --- | --- |
| Corregir acceso en Miruro | Es la solución directa si el dueño confirma un endpoint público o autoriza el acceso/configuración necesario. | Depende del operador; no conocemos la política exacta. |
| Probar otro provider configurado | El manager ya continúa con el siguiente registro después de un error tipado; se añadió una regresión de 403. | La prueba usa providers fake. En el composition root actual, Miruro es automático; Wikimedia requiere habilitación y `user_sources` entradas explícitas. Wikimedia tiene evidencia histórica de reproducción remota de Namakura Gatana, pero no es un fallback general ni cubre AniList 100240. |
| Enlaces de `streamingEpisodes` de AniList | Implementado: se muestran como páginas externas HTTPS y se copian para apertura manual. | AniList puede no publicar enlaces o estos pueden estar caducados; no reproducen dentro de Kongroo. |
| Reintentar con otra identidad, cookie, proxy, fingerprint, mirror o superar un challenge | Rechazado. | Cambiar la solicitud para sortear una denegación no es una solución legítima autorizada. |

Un 403 podría tener solución si el endpoint, la configuración de la aplicación o
los permisos de un servicio controlado por el propietario estuvieran mal; aquí
no se observó esa evidencia. No se puede determinar la regla específica desde
una respuesta 403 aislada.

## Cambios preparados

- `AnimeEpisodeMetadata` conserva `externalWatchUri` como dato de catálogo,
  separado de una fuente de reproducción.
- El query de AniList pide `streamingEpisodes { title thumbnail site url }`.
- El parser/caché acepta el URL únicamente con esquema HTTPS, host y sin
  credenciales embebidas.
- La ficha presenta una lista perezosa y un botón de copiar. La acción usa el
  portapapeles de Flutter y reporta resultado; el usuario abre después la página
  copiada en un servicio externo.
- El mensaje de denegación no anuncia reintento automático.
- Se agregó un caso al test del manager: un provider fake devuelve 403 y uno
  fake posterior produce fuentes. Esto prueba la continuidad del registro, no
  el funcionamiento de un provider remoto.
- No se modificaron el engine `media_kit/libmpv`, controles, máquina de estado,
  subtítulos ni dependencias del reproductor. No se añadieron paquetes.

## Evidencia y pruebas

### Pruebas ejecutadas

Con Flutter `3.50.0-0.4.pre` / Dart `3.14.0`:

```text
flutter test --no-pub --concurrency=1 \
  test/data/anilist/anilist_client_test.dart \
  test/data/anilist/anilist_metadata_provider_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/catalog/playback_resolution_message_test.dart \
  test/catalog/anime_detail_external_streaming_links_test.dart
47/47 passed

flutter analyze --no-pub
No issues found

flutter build linux --debug --no-pub
Built build/linux/x64/debug/bundle/anime_app
```

La suite completa Flutter ejecutada en serie terminó con **336 aprobadas, 10
omitidas y 2 pruebas fallidas por timeout**: un caso del spike HTTP ranges del
player con límite de 12 s y un caso de selección de pista libmpv con límite de
30 s. Ambos casos pasaron al ejecutarlos individualmente con `--concurrency=1`.
Esto reduce la evidencia de regresión aislada, pero no demuestra la causa del
timeout en la suite completa. No se modificó el engine para ocultarlos. Durante
la suite también aparecieron mensajes de Fontconfig por falta de caché global
escribible; no se cambiaron permisos del sistema.

### No ejecutado / no demostrado

- No se hizo una solicitud actual a Miruro o AniList ni se validó que AniList
  publique enlaces para un título concreto.
- La prueba histórica de Wikimedia/Namakura Gatana no se repitió y no representa
  playback del provider Miruro ni fallback para AniList 100240.
- El widget test comprueba presentación y callback de copia; no verifica el
  portapapeles del sistema ni abrir la página con un navegador real.
- No se recorrió ficha → episodio → fuente → libmpv con un vídeo externo.
- No se midieron RAM, CPU, arranque, playback, 4 GB de RAM ni fugas para este
  cambio. No se probó Android o Windows.
- El build Linux comprueba compilación, no comportamiento visual/externo.

## Hallazgos

### OC04-P1-01 — origen Miruro aún deniega y no hay playback externo

- **Estado:** abierto / bloqueo externo no diagnosticado.
- **Ubicación:** `app/lib/data/player/providers/playback_providers_module.dart:20-47`
  registra Miruro como provider automático; la evidencia histórica está en
  `app/lib/data/player/providers/README.md` y la auditoría OC-03.
- **Evidencia:** las consultas públicas previas para AniList 100240 recibieron
  403 antes de episodios y fuentes. Esta misión no repitió la solicitud. La
  suite de esta misión no contiene respuesta de red real.
- **Reproducción:** consultar el registro existente y la evidencia OC-03; no
  repetir el GET bloqueado hasta que haya nueva autorización/ruta documentada.
- **Consecuencia:** no se obtiene una fuente para el flujo Miruro/AniList 100240;
  el conteo sigue en 0. La evidencia histórica opt-in de Wikimedia/Namakura
  Gatana es un caso separado.
- **Acción recomendada:** usar un endpoint que el operador documente como
  público, pedir al operador que corrija/autorice la ruta, o integrar un provider
  distinto con acceso público ordinario. Validar búsqueda/episodio/medio y
  reproducción visible con media_kit antes de marcarlo funcional.
- **Regresión necesaria:** smoke limitado de la ruta autorizada y test de
  integración que confirme medio, primer frame, audio y cierre/cambio de fuente.

### OC04-P2-01 — fallback externo depende de metadata y de apertura manual

- **Estado:** implementación local completada; validación del sistema pendiente.
- **Ubicación:** `app/lib/app/catalog/detail/anime_detail_tab_content.dart:154-237`
  y `app/lib/app/catalog/anime_detail_page.dart:163-179`.
- **Evidencia:** el test de widget verifica el callback de copia, no el
  portapapeles del sistema. La fuente oficial de AniList describe las páginas
  externas, pero no garantiza cobertura para cada anime o episodio.
- **Reproducción:** el test focalizado pasa; falta abrir una ficha con enlace
  real y comprobar copia/pegado/apertura manual en Fedora.
- **Consecuencia:** la salida puede no aparecer si AniList no publica URL y
  requiere un paso manual; no es un fallback de libmpv.
- **Acción recomendada:** realizar una comprobación manual cuando haya una ficha
  con metadatos disponibles; mantener el texto explícito sobre apertura externa.
- **Regresión necesaria:** prueba de portapapeles en plataforma y prueba de UI
  con datos de AniList obtenidos por vía autorizada, sin automatizar desafíos.

## Segunda revisión adversarial

Se hizo una segunda lectura propia, no una revisión independiente. Se comprobó
que la URL externa no se convierte en `PlaybackSource`, la validación no admite
`javascript:` ni credenciales en URL, el widget genera filas perezosas, el
portapapeles comprueba `mounted` después del `await`, el manager sigue de forma
secuencial entre providers configurados y no se crean nuevos clientes HTTP para
la ruta de copiado. El test del manager es determinista/fake y no se trata como
evidencia de cobertura remota. El test de widget no verifica clipboard nativo.

No se encontraron regresiones P0/P1 introducidas por este parche. El P1 de
reproducción externa sigue abierto como criterio de producto; esta alternativa
no cierra S0 ni acredita un servidor.

## Archivos del cambio OC-04

- `app/lib/domain/catalog/anime_detail_metadata.dart`
- `app/lib/data/anilist/anilist_client.dart`
- `app/lib/data/anilist/anilist_detail_fields.dart`
- `app/lib/app/catalog/anime_detail_page.dart`
- `app/lib/app/catalog/detail/anime_detail_tab_content.dart`
- `app/lib/app/catalog/playback_resolution_message.dart`
- `app/lib/data/player/providers/mock/mock_playback_provider.dart`
- `app/test/data/anilist/anilist_client_test.dart`
- `app/test/data/anilist/anilist_metadata_provider_test.dart`
- `app/test/application/playback_provider_manager_test.dart`
- `app/test/catalog/playback_resolution_message_test.dart`
- `app/test/catalog/anime_detail_external_streaming_links_test.dart`
- README y estado: `app/lib/data/anilist/README.md`,
  `app/lib/app/catalog/README.md`, `app/lib/app/catalog/detail/README.md`,
  `app/lib/data/player/providers/README.md`, `PROGRESS.md`, `TESTING.md` y los
  documentos de memoria enlazados desde aquí.

Este listado describe los archivos del trabajo OC-04 observado, no todos los
cambios del checkout concurrente. No se hizo staging, commit ni push.

## Anexo — DNS y Cloudflare en Anilili

Se revisó en solo lectura el `Anilili-main.zip` que el propietario adjuntó, en
particular `AppDns.kt`, `AutoDns.kt`, `CloudflareClearance.kt`,
`CloudflareInterceptor.kt` y `MiruroCatalogApi.kt`, y se contrastó con el
desktop upstream fijado en la auditoría OC-03.

- `AppDns.kt` ofrece DoH de Google, Cloudflare, Cloudflare Security, AdGuard,
  Quad9, DNS.SB y Canadian Shield. Su modo automático prueba DNS seguro cuando
  el resolver de la red no da respuesta, devuelve un sinkhole o se sospecha una
  página de bloqueo por DNS. Eso resuelve **DNS**, antes de la conexión HTTP.
- `MiruroCatalogApi.kt` tiene varios orígenes públicos y continúa con fallos de
  red/5xx. Al recibir un 4xx (incluido 403), lanza la denegación. El comentario
  dice que los mirrors sirven la misma API y que un 4xx es la respuesta del API.
  El código desktop consultado en
  [el commit fijado](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/miruro.rs)
  expresa la misma política.
- `CloudflareClearance.kt` y `CloudflareInterceptor.kt` guardan y vuelven a
  adjuntar un clearance de Cloudflare obtenido por el componente WebView,
  vinculado a la identidad de navegador. El desktop describe `wreq` con
  emulación TLS/HTTP2 Chrome y un perfil Edge/WebView2 para reutilizar ese
  clearance; ver su [transporte de red fijado](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/net.rs).
  Es una ruta de emulación/reutilización de estado anti-bot, no DNS.

La evidencia de respuesta para Kongroo fue HTTP 403 después de resolver y
conectar con ambos orígenes observados; no fue `NXDOMAIN`, ausencia de respuesta
DNS ni sinkhole. Cambiar a un resolver DoH puede arreglar un bloqueo de DNS del
ISP, pero no quitar una denegación HTTP del edge de Cloudflare. Kongroo ya tiene
los orígenes Miruro documentados en `miruro_catalog_api.dart` y corta 4xx. No se
añadieron mirrors ni configuración DNS: hacerlo aquí no está respaldado como
arreglo del 403 y podría convertir una denegación explícita en una tentativa de
evadir el control.

El mecanismo de emulación/clearance de Anilili no se portó por la restricción
del propietario de no evadir CAPTCHA, autenticación u otros controles de acceso.
**Estado después de este anexo:** la causa exacta sigue sin diagnóstico; 403 del
flujo Miruro/AniList 100240 sigue abierto; alternativa de enlace externo sigue
disponible cuando AniList la publique; reproducción dentro de Kongroo no queda
resuelta por DNS.

## Addendum — comparación de transporte y caché de Anilili

Se compararon en solo lectura el ZIP Android adjunto y el desktop Anilili fijado
en `e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`, además de los archivos actuales
de Kongroo. No se hicieron nuevas solicitudes a Miruro.

### Diferencias observadas

1. **Android de Anilili:** `MiruroCatalogApi.kt` crea un `OkHttpClient` separado
   sin instalar `CloudflareInterceptor`; envía una solicitud HTTPS GET ordinaria
   con contexto de navegador. El comentario del archivo registra que el 2026-10-03
   los cinco mirrors devolvieron `config` 200 sin cookie. La misma clase detiene
   cualquier 4xx, incluidos 403. El interceptor de Cloudflare sí se instala en
   el cliente de Anivexa (`AnivexaClient.kt`), no en el cliente del catálogo
   Miruro. Por tanto, el código no respalda la conclusión de que DoH o el
   interceptor de clearance sean lo que hace funcionar `bee` en Android.
2. **Desktop de Anilili:** su cliente compartido `Http::new()` usa `wreq` con
   un perfil TLS/HTTP2 que el propio código describe como emulación de Chrome.
   `Miruro::get` usa ese cliente y adjunta contexto de petición del mismo origen.
   El cliente también define un perfil Edge/WebView2 para solicitudes con un
   clearance ganado por WebView, y un modo sin emulación para otros CDN. El
   código confirma que esos modos existen; no demuestra cuál de ellos se usó en
   la reproducción concreta de `bee` ni qué condición de Miruro produjo el 403.
3. **Cachés de Anilili:** Android guarda configuración 30 min y respuestas
   `/play` 2 min en memoria. Desktop usa caché persistente con respuestas
   antiguas para catálogo/episodios, y mantiene resultados de fuentes 8 min en
   memoria porque las URLs pueden caducar. Es posible que una ficha siga
   mostrando episodios desde caché o que una fuente ya resuelta siga disponible
   brevemente durante una denegación nueva. Esto no invalida la reproducción
   observada por el propietario; limita lo que esa observación prueba sobre una
   consulta HTTP nueva en el mismo instante.
4. **Kongroo:** `PublicPlaybackHttp` usa Dio con `Kongroo/0.1`, sin el transporte
   TLS/HTTP2 de Anilili desktop. `MiruroCatalogApi` no emula un navegador, no
   transporta clearance y se detiene en 4xx. La composición configura el TTL de
   respuestas de fuentes Miruro en cero, así que una lista anterior de fuentes
   no explica el GET de fuentes de esta ejecución. Los valores de configuración,
   título y episodios sí tienen cachés locales acotadas; obtener fuentes de un
   episodio todavía requiere consultar `/play`.

### Qué explica y qué no

La diferencia de transporte desktop es una hipótesis técnica plausible para una
respuesta distinta entre Anilili y Kongroo, y el cambio temporal entre la
medición Android de 2026-10-03 y el 403 observado en Fedora también es plausible.
Ninguna queda aislada por una prueba A/B autorizada. El registro de Kongroo solo
conserva HTTP/2 403, `text/html` y `server: cloudflare`; no conservó el cuerpo,
`cf-mitigated` ni una traza de DNS. La evidencia permite decir que Cloudflare
respondió tras completar DNS/TLS, pero **no permite clasificarlo como CAPTCHA**
ni identificar si fue regla WAF, reputación de IP, región, política del origen u
otra causa.

DoH no corrige esa respuesta HTTP; probar más aliases tampoco es el siguiente
paso, porque los dos clientes Anilili examinados, igual que Kongroo, tratan 4xx
como respuesta terminal. No se recomienda copiar el perfil anti-bot ni reutilizar
clearance. Una vía verificable es que el operador documente/autorice el acceso
de la aplicación o publicar un endpoint accesible ordinariamente; en paralelo,
Kongroo puede continuar con una fuente independiente que no presente este
bloqueo.

### Fuentes y estado de verificación

- Código desktop: [Miruro](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/miruro.rs),
  [transporte](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/net.rs),
  [caché y resolución de fuentes](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/catalog.rs),
  [TTL de fuentes](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/app.rs).
- Android: inspección local de solo lectura del ZIP suministrado, archivos
  `MiruroCatalogApi.kt`, `PipeClient.kt`, `AnivexaClient.kt` y `AppDns.kt`.
- Kongroo: [cliente de catálogo](../../../app/lib/data/player/providers/miruro/miruro_catalog_api.dart),
  [transporte compartido](../../../app/lib/data/player/providers/public_playback_http.dart)
  y composición de providers.
- No se ejecutaron pruebas ni sondas de red en este addendum; no hubo cambios de
  código, configuración DNS, staging, commit o push. El 403 del flujo Miruro
  sigue abierto y no se confirma reproducción de `bee` dentro de Kongroo.

## Follow-up — evaluación de integrar el método Android

Se comparó `MiruroCatalogApi.kt`/`PipeClient.kt` del ZIP adjunto con el adapter
actual de Kongroo. La parte de protocolo ya está integrada: mapeo por AniList,
`config`, lookup del título con `limit=100`, episodios paginados, `/play`,
decodificación XOR+gzip, agrupación de alternativas y entrega normalizada al
`PlaybackProviderManager`/resolver existentes. La ficha puede pedir `/play`
para el episodio elegido sin depender de una lista de servidores codificada a
mano. No se necesita añadir código Android al núcleo Dart.

No se identificó una diferencia de endpoint, parámetro ni formato que explique
el 403 actual. La diferencia observada está en la identidad/contexto del cliente
HTTP; cambiarla para que una solicitud rechazada pase el filtro de Cloudflare
sería eludir la denegación, no integrar una capacidad funcional del catálogo.
Por ello, esta solicitud no produjo cambios en el proveedor ni una nueva prueba
de red. Las pruebas focalizadas existentes se ejecutaron ahora:

```text
flutter test --no-pub --concurrency=1 \
  test/data/player/providers/miruro_catalog_provider_test.dart \
  test/data/player/providers/public_playback_http_test.dart \
  test/data/player/providers/playback_providers_module_test.dart
20/20 passed
```

Incluyen fixtures/fakes; una prueba confirma que 403 no reintenta otro mirror.
No son evidencia de acceso live. La integración queda preparada para un endpoint
o permiso documentado por el operador; hasta entonces, Miruro sigue bloqueado y
no hay reproducción `bee` confirmada en Kongroo.
