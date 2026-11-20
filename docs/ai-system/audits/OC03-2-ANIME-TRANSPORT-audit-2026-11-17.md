# OC-03.2 · Auditoría de los hosts de anime

Resultado parcial. La causa interna de las respuestas de los dos CDN no
está determinada. La etapa HTTP fallida se confirmó en red y el bloque de
transporte puede informarla sin abrir una sesión fallida de libmpv.
Ver [checkpoint](../missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md)
para cronología, fuentes primarias y limitaciones.

## Hallazgos de código

| ID | Severidad | Evidencia | Estado |
|---|---|---|---|
| HP-01 | P1 | El resolver consideraba cualquier declaración de un MP4 válido como candidata aunque el CDN devolviera 403 o 500. | Se añadió verificación HEAD con MIME permitido a los dos perfiles en la composición del producto. HEAD solo verifica su propia respuesta. Subsiste la necesidad de acceso autorizado y cuadros reales. |
| HP-02 | P2 | YourUpload devolvió 500 y una alternativa posterior sin medio lo sustituyó por `unsupportedEmbed`. | El manager conserva respuestas concretas y prioriza un Retry-After vigente. La sonda final devolvió `unavailable stage=media status=500`. |
| HP-03 | P2 | La sonda usaba una identidad distinta de libmpv si el perfil no declaraba UA. | Perfil de UA por medio, validado con dos solicitudes reales de loopback. Se conserva el aislamiento real de libmpv al cambiar de fuente. |
| HP-04 | P2 | Las aperturas directas y Play podían borrar un fallo asíncrono antes de que la UI lo mostrara. | El coordinador preserva el error de la fuente. La regresión reproduce Stop→Play con snapshot de HTTP 403. Se reconoce el código nativo solo si está explícito. |
| HP-05 | P2 | Un 429 de origen sin cooldown propio podía evitar el breaker. Un rechazo por cooldown podía prolongarlo indebidamente. | HTTP público aplica plazo por origen. El breaker cuenta un 429 legado sin plazo propio. La prueba local verifica Retry-After sin una segunda petición. |
| HP-06 | P2 | HTTP 200 con texto o JSON podría parecer medio validado. | HEAD MP4 requiere `video/mp4` o `application/octet-stream`. La prueba devuelve 200 `text/plain` y verifica rechazo. Cambios de origen se rechazan aun cuando la URL destino esté en la familia de dominios. |
| HP-07 | P1 | Los dos CDN prioritarios no entregaron un medio accesible en las sondas de esta sesión. | Abierto. MP4Upload 403 en HEAD. YourUpload 500 en HEAD y Range. Se mantienen experimentales. Falta acceso legítimo y vídeo visible. |

La revisión adversarial se hizo con un auditor independiente de solo lectura.
Se verificaron contratos en `public_playback_http.dart`,
`public_embed_host_resolver.dart`, `public_embed_host_profiles.dart`,
el manager, el breaker y el coordinador. No se cambiaron opciones globales
de mpv, dependencias ni el lockfile.

## Validación

Fedora con Flutter 3.47.9 y Dart 3.13.7 del proyecto, Dio 5.11.1,
media_kit 1.2.6 y libmpv del sistema. El análisis estático final quedó limpio.
La suite con los opt-in de cabeceras, HLS local y descubrimiento real aprobó
349 y omitió 8. Una corrida focalizada posterior con el test adicional del
UA del resolver aprobó los 8 casos de transporte. El build Linux release
pasó. No se consideró evidencia de nuevos hosts el canario previo de
Wikimedia ni los fixtures. Android y Windows quedan sin ejecución.

La prueba con mouse se ejecutó después de las regresiones. La ficha de
One Piece 1 mostró 403 y la ficha de Naruto 1 mostró 500. El retorno a la
búsqueda se verificó en Naruto. La reproducción bloqueada conservó el
catálogo operativo. Persisten las limitaciones de permisos y red indicadas
en HP-07.
