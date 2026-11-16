# Auditoría profunda — Port S0-A de Anilili/Miruro

> **Corte histórico:** esta auditoría revisó la integración Miruro antes de su
> retirada posterior. El runtime actual no registra esos archivos; la
> [auditoría de limpieza posterior](S0-provider-cleanup-followup-audit-2026-11-15.md)
> es la referencia vigente sobre el árbol.

**Fecha:** 2026-11-15
**Alcance:** integración de catálogo Miruro, resolver directo y enlaces con el manager y player existentes.
**Revisor:** revisión del coordinador y segunda pasada adversarial local; no es una auditoría independiente.
**Estado:** no aceptable como reproducción de producto; el gate S0 de playback continúa abierto.
**Git:** rama `main`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`; había cambios previos sin commit, que se preservaron. No hubo staging, commit ni push.

## Resumen

El código implementa el parsing del catálogo Miruro, una API Dio acotada y un
resolver HTTPS HLS/MP4. Los componentes usan el `PlaybackProviderManager` y el
`PlaybackVideoHostResolver` existentes; la reproducción sigue en el único
`MediaKitSpikeEngine`/libmpv. El cliente no sigue redirects, no rota mirrors,
no reintenta y no lleva cookies, credenciales, headers de navegador ni
challenge-handling.

Las peticiones GET ordinarias al endpoint público de config/lookup devolvieron
403. No se obtuvo episodio ni media accesible y no se abrió libmpv con fuente
externa. La integración queda **implementada, pero bloqueada externamente y no
verificada funcionalmente**. La meta S0 permanece `0/70`.

## Alcance y procedencia

Se adaptaron los modelos, forma de respuesta y reglas del catálogo Miruro de
Anilili en commits fijados en el
[informe de port S0-A](../missions/S0-ANILILI-PORT-REPORT.md). Las licencias
MIT-0 de los dos commits consultados están allí con enlaces al upstream. Se
adaptó el esquema de datos y no se copió el runtime Android/WebView ni los
componentes de sesión o desafío. `dio` está fijado en `app/pubspec.lock` como
5.11.1.

## Revisión de límites y ciclo de recursos

- **Provider:** acepta solo un ID externo numérico de AniList; el ID Miruro se
  restringe a caracteres de ruta seguros. Consulta páginas de episodios con
  tope de tres y config con TTL de diez minutos. No usa título ambiguo como
  sustituto de identidad.
- **Parser:** limita entrada codificada a 1 MiB y expansión gzip a 4 MiB;
  valida datos, tipos de pista, URLs HTTPS y formatos HLS/MP4. Mantiene embeds
  fuera de la ruta de media directa.
- **HTTP:** una sola raíz canónica; acota conexión/envío/recepción, bytes y
  cancelación; rechaza redirecciones y mapea 403 a fallo `unauthorized`.
  Cierra el stream HTTP no necesario en estados de error. El composition root
  posee un `Dio` y `close()` es idempotente.
- **Headers:** se reenvía solo `Referer` público validado por el contrato. Se
  eliminan Origin/cookies/autorización y cualquier header de cliente.
- **Resolver:** solo HTTPS HLS/MP4, sin extracción de iframe ni GET de
  manifiesto. Limita tiempo DNS y rechaza direcciones no globales. La segunda
  pasada encontró prefijos IPv6 especiales/documentales aceptados por el
  filtro inicial; el denylist conservador se reforzó y se agregó una regresión.
  La lista se contrastó con el
  [registro de direcciones especiales IANA](https://www.iana.org/assignments/iana-ipv6-special-registry).
- **Riesgo residual:** el DNS se consulta antes de entregar la URI, pero libmpv
  resuelve el nombre otra vez. Esto es DNS TOCTOU/rebinding potencial y no queda
  resuelto por la comprobación previa. No se afirmó pinning de IP.
- **UI/player:** no se modificó la UI ni se añadió un player. No hay datos
  externos reproducibles para probar la ruta ficha → episodio → selector →
  libmpv.

## Hallazgos

### P1 — Gate esencial de producto no satisfecho

**Evidencia:** GET públicos ordinarios a config/lookup respondieron HTTP 403;
el smoke ejecutado con Dio clasificó `unauthorized`. No hay episodio, fuente
directa, manifiesto accesible, dimensiones de video, primer frame, avance,
audio, seek o cierre de reproducción externa.

**Impacto:** esta integración no cumple el objetivo de ver anime real. CI y
fixtures prueban el contrato Dart y libmpv local por separado; no cierran el
recorrido integrado ni suman títulos al contador 0/70.

**Tratamiento:** no se evadió el 403 ni se repitió la petición con otros
mirrors, cookies, huella de navegador o headers diseñados para alterar la
respuesta. Gate de playback queda pendiente hasta que una solicitud pública
ordinaria obtenga media accesible.

### P2 — DNS TOCTOU en el salto a libmpv

**Evidencia:** el resolver valida las direcciones obtenidas por DNS y descarta
los bloques locales/especiales implementados, pero el engine recibe un hostname
y ejecuta su resolución posteriormente.

**Impacto:** la validación no garantiza que el socket de libmpv alcance la
misma dirección consultada. No se declara mitigación completa contra rebinding.

**Acción pendiente:** estudiar un contrato de transporte que conserve TLS y
pueda fijar el destino de red sin duplicar el engine. Si no es viable con
libmpv/`media_kit`, mantener el riesgo documentado y validar cada redirección
solo mediante mecanismos ordinarios autorizados.

### P2 — Paridad y validación de media incompletas

El dominio actual no transporta subtítulos/skip-times desde esta fuente, DASH
no está habilitado, y el resolver no descarga/inspecciona manifiestos HLS ni
prueba expiración/headers del media real. Esos puntos siguen pendientes porque
la API no entregó una URI accesible; no se inventaron respuestas para cubrirlos.

### P2 — Anivexa sin adaptación operativa

Anivexa se inspeccionó documentalmente, pero no hay un provider registrado ni
se completa la matriz de los 28 candidatos. De los 28 se sondearon solo tres
rutas en vivo: AniChan/AniPM dieron 403 en probes ordinarios; Zoko devolvió
página/payload, pero el manifiesto observado también dio 403 sin cabeceras
adicionales. El [cliente upstream](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnivexaClient.kt)
usa `CloudflareInterceptor` en el cliente compartido; su catálogo indica que
AnimePahe usa WebView. No se implementaron sesiones, fingerprints, challenges,
firmas o transformaciones para cambiar denegaciones. El identificador MAL
requerido por Zoko tampoco forma parte del `PlaybackEpisode` actual. El alcance
estático restante y cualquier adapter individual que use GETs públicos sigue
pendiente; no se presenta el sondeo de tres como auditoría completa de Anivexa.

## Pruebas y evidencia ejecutadas

Toolchain usada: Flutter `3.50.0-0.4.pre`, Dart `3.14.0-315.3.beta`, desde
`.ai-local/toolchains/flutter`; ninguna modificación del SDK global.

- Suite focalizada Miruro + composition root: **22 aprobadas**; el smoke live
  queda omitido salvo opt-in. El test del provider incluye denegación de IPs
  IPv4 privadas/locales y seis prefijos IPv6 especiales.
- `dart analyze lib test`: sin issues.
- `flutter analyze --no-pub`: sin issues.
- `dart format`: 187 archivos examinados, 0 con cambios de formato.
- `scripts/check_imports.dart` y casos positivos/negativos del checker: pasan.
- `python3 tools/ai/memory.py check`: pasa.
- `bash scripts/ci.sh`: exit 0; 40 pruebas Python, 288 Flutter aprobadas, 7
  optativas omitidas. Incluye tests del reproductor con fixture local, no
  contenido Miruro.
- `flutter build linux --release --no-pub`: exit 0; generó
  `app/build/linux/x64/release/bundle/anime_app`.
- Smoke live con cliente Dio: respuesta 403 clasificada como
  `blocked_or_unavailable / unauthorized`. Se ejecutó una vez; no se reintentó.
- `git diff --check`: exit 0. Un chequeo adicional cubrió whitespace en 11
  ficheros S0-A nuevos/actuales; 21 referencias Markdown locales explícitas
  resuelven dentro del repositorio.
- Búsqueda de patrones comunes de credenciales (tokens GitHub/AWS, claves
  privadas, bearer tokens y contraseñas/API keys literales) en esos 11 ficheros:
  sin coincidencias. Esto no reemplaza una revisión general de secretos del
  repositorio; el fixture `token=fixture` es un valor sintético de prueba.

CI imprimió errores de caché Fontconfig no escribible en algunos tests nativos,
pero finalizó exit 0. Un test existente reportó RSS del proceso al repetir
aperturas con un fixture local; esos datos no representan medición del provider,
del equipo de 4 GB ni prueba de fugas de streaming.

## Segunda pasada adversarial

Se releyeron API, parser, provider, resolver, composición y pruebas buscando
cancelaciones tardías, redirects, tamaños sin cota, rutas controladas por el
servidor, hosts/IP privados, duplicación de servidores, cierre de recursos y
afirmaciones de playback. La revisión detectó el filtro IPv6 incompleto, lo
corrigió y pasó la regresión. La pasada la realizó el mismo coordinador y no es
una auditoría independiente; por eso no se usa para afirmar aceptación.

## Estado y trabajo restante

- Gate A (paridad): parcial.
- Gate B (primer playback real): **no cumplido, bloqueado por 403**.
- Gate C (fallback/selección real): pendiente de varias fuentes multimedia.
- Gate D (Anivexa): pendiente.
- UI Wayland y rendimiento en hardware Fedora de 4 GB: no verificados.
- `STATUS` y `HANDOFF` conservan el siguiente paso; no avanzar F1/G1 ni marcar
  S0 completa mientras el P1 siga abierto.

No se hizo commit, push ni staging. El árbol tenía cambios y archivos no
rastreados previos a esta misión; esta revisión no los atribuye a S0-A ni los
descarta.
