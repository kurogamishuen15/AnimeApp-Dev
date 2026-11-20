# Catálogo Miruro

## Estado verificado · 2026-11-20

La integración **funciona en vivo y está verificada hasta reproducción real
(N4)**. El registro existente `miruro-catalog` sigue siendo el adaptador; se le
añadió el transporte HTTP/2 y un proxy loopback, sin duplicar adaptador, manager
ni reproductor.

| Hecho | Evidencia |
|---|---|
| `/api/config` | `200 application/json`, 6.798 B |
| Búsqueda AniList `100240` | Tokyo Ghoul:re = `jTKTTY5jgmnczRbDtpS__otDrAfAXd2b` |
| Episodio 9 | "Play: Ghost" (`200`) |
| Fuentes | `200`; 18 streams HLS en 3 tracks; 9 `PlaybackSource` |
| Medio | master → variante → segmentos AES-128; `206` + `Content-Range` |
| libmpv | duración `0:24:09.629955`, audio 3 pistas, `PLAYING`, `SEEK 0:00:40` |
| Proxy loopback | `http://127.0.0.1:<port>/media/<id>`; libmpv `0:24:09.629955`, `PLAYING`, `SEEK 0:00:40.166171` |
| Backend caído | el manager resuelve por otro proveedor y registra el fallo |

El informe completo, con la matriz de origen, los códigos por ruta, las
decisiones y lo que falló, está en
[OC-07](../../../../../../docs/ai-system/missions/OC07-MIRURO-FRONTEND-BACKEND-CONTRACT-2026-11-19.md).

## Cómo se desbloqueó la ruta

Dos condiciones, no una:

1. **Cabecera de contexto fetch-metadata**: `Sec-Fetch-Site: same-origin`.
   Es la que un navegador pone al llamar al backend de su propio origen. Sin
   ella, `/api/config` responde `403` con block page de Cloudflare; `same-site`
   también devuelve `403`. `Origin`, `Referer`, `Accept` y el UA no son el
   factor: con la cabecera correcta, un UA propio y un UA Firefox reciben el
   mismo `200`.
2. **HTTP/2**: la ruta de catálogo solo se sirve por `h2` en los cuatro espejos
   (`.to`, `.bz`, `.cx`, `.tv`). Por HTTP/1.1 devuelve `403`; `/health` responde
   `200` por ambos. El cliente de `dart:io` es HTTP/1.1, y esa era la causa del
   403 histórico.

No se usaron cookies, `cf_clearance`, impersonación TLS ni challenges. El
patrón se tomó del cliente público
[`stepbrobd/miruro`](https://github.com/stepbrobd/miruro/tree/408259661cc7335bafc99ef6e9b7f4a588192a04)
(commit `4082596`): UA, cabeceras, HTTP/2 y decodificación XOR+gzip.

## Responsabilidad

`MiruroCatalogPlaybackProvider` adapta el catálogo público REST de Miruro al
contrato `EpisodeSourceAdapter` que consume `PlaybackProviderManager`. Mapea un
**ID de AniList exacto** (`100240`), descubre el título, pide el `play` del
episodio y normaliza streams HTTPS directos y HLS. No busca por título difuso,
no interpreta iframes y no crea un player ni un manager.

Está registrado con prioridad 100, después de los proveedores locales, y se
desactiva con `KONGROO_ENABLE_MIRURO=0` o `KONGROO_ENABLE_MIRURO_BACKEND=0`.

## Arquitectura

| Archivo | Función |
|---|---|
| `miruro_http2_client.dart` | Transporte HTTP/2 acotado: ALPN `h2`, pool por host, timeout, límite de bytes. Expone `MiruroCatalogTransport` para pruebas. |
| `miruro_catalog_api.dart` | Rutas `/api/…`, cabeceras de contexto, mapeo de estado a `PlaybackProviderFailureKind`, `probeHealth()` por `/health` (HTTP/1.1 basta). |
| `miruro_catalog_parser.dart` | Parser Dart puro de config, título, episodios, tracks, servidores y streams. Propaga `Referer` y `Origin` declarados. |
| `miruro_media_proxy.dart` | Proxy loopback: publica cada fuente como `http://127.0.0.1:<port>/media/<id>`, aplica cabeceras, reenvía `Range`, preserva `206`/`Content-Range` y reescribe playlists HLS. |
| `miruro_catalog_playback_provider.dart` | Matching por AniList, fases de episodios/fuentes, TTL/LRU internos y bridge al manager. |

El proxy existe por motivos funcionales: centraliza cabeceras, hace correcto el
seek al preservar rangos, oculta la rotación de mirror/token y presenta la fuente
como interna con etiqueta `Miruro (Kongroo)`. Solo acepta `GET` por loopback y
valida cada hijo contra los hosts que la playlist del proveedor declara y la
familia de dominio del stream registrado.

### Dependencia añadida

`http2 3.2.0`, paquete mantenido por el equipo de Dart, Dart puro (Linux y
Android). Se añadió porque el backend solo negocia `h2` y no existe sustituto en
`dart:io`. Queda aislada en `MiruroHttp2Client`; el motor multimedia no cambia.

## Endpoints verificados

| Ruta | Código | Formato |
|---|---:|---|
| `GET /health` | 200 | JSON, `version` 1.15.9 |
| `GET /api` (exacto) | 404 | HTML del frontend |
| `GET /api/config` | 200 | JSON |
| `GET /api/v1/anime?q=…&limit=…&sort=-popularity` | 200 | XOR+gzip |
| `GET /api/v1/anime/<title-id>/episodes?limit=10000` | 200 | XOR+gzip |
| `GET /api/v1/anime/<title-id>/episodes/<n>/play` | 200 | XOR+gzip |

Los cuerpos de catálogo van como `application/octet-stream`: XOR con la clave
`miruro/catalog` y después gzip. Se decodifican con límite de tamaño; no se
considera protección de acceso. El catálogo también puede responder JSON plano.

El endpoint `play` puede devolver varios providers, servidores y calidades. Las
calidades se agrupan por host y se elige la más alta declarada; el nombre visible
indica la resolución declarada, no un bitrate medido. Solo se emiten streams
directos HTTPS con formato conocido (MP4/HLS/DASH/WebM); los iframes quedan
fuera.

Los tokens de `anikoto` caducan (~1 h, `exp` en base64 en `?token=`), así que una
fuente cacheada demasiado tiempo falla y hay que volver a pedir `play`.

## Seguridad y manejo de errores

- Solo el dominio oficial `www.miruro.cx`; sin fallback a dominios retirados.
- Sin cookies, `Authorization`, sesión ni tokens ajenos. Los 4xx detienen el
  intento del adaptador; el manager decide el fallback.
- Cabeceras de contexto permitidas y validadas: `Referer`/`Origin` públicos HTTPS
  sin query ni userinfo, `User-Agent` acotado y `Sec-Fetch-Site` en un conjunto
  cerrado (`same-origin`, `same-site`, `cross-site`, `none`).
- El proxy solo escucha en `127.0.0.1`, solo atiende `GET`, y no sigue un hijo
  hacia un host que el proveedor no haya declarado en su playlist ni hacia uno
  fuera de la familia del stream registrado. Solo acepta HTTPS público: sin IP,
  sin nombres especiales y sin puerto distinto de 443.
- Errores de red, timeout, rate limit, denegación, respuesta inválida y
  cancelación se convierten al resultado tipado del dominio.

## Pruebas

Desde `app/`:

```bash
# Unitarias: transporte h2 simulado, parser, proxy loopback, contrato
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/miruro_catalog_provider_test.dart \
  test/data/player/providers/miruro_media_proxy_test.dart \
  test/player/oc07_miruro_failover_test.dart \
  test/domain/playback_provider_contract_test.dart

# Live: resolución real y reproducción directa
KONGROO_TEST_REAL_MIRURO=1 \
  ../.ai-local/toolchains/flutter/bin/flutter test \
  test/player/oc07_miruro_live_playback_test.dart

# Live: reproducción a través del proxy loopback
KONGROO_TEST_REAL_MIRURO_PROXY=1 \
  ../.ai-local/toolchains/flutter/bin/flutter test \
  test/player/oc07_miruro_proxy_playback_test.dart

# Sonda de resolución sin player
../.ai-local/toolchains/flutter/bin/dart run tool/oc07_miruro_probe.dart 9
```

Las pruebas offline usan fixtures JSON y XOR+gzip, adaptadores `Dio` falsos y un
servidor HTTP local para el proxy. Las live requieren red y dependen de que el
backend, los mirrors y los tokens de los hosts estén disponibles; un 403 de un
host concreto no invalida la integración si otro candidato abre.

## Procedencia

Se adaptó la forma del protocolo y sus modelos del código de Anilili que el
propietario proporcionó; no se copió runtime Kotlin/Android, WebView,
Cloudflare/challenge, cookies, clients de navegador ni resolutores de
Anivexa/AniChan. La referencia upstream y el aviso MIT-0 están en
[`docs/third-party/ANILILI-MIT-0.md`](../../../../../../docs/third-party/ANILILI-MIT-0.md).
El [informe de migración](../../../../../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md)
separa la evidencia de código de la disponibilidad del servicio.

Marco de consumo: lectura con `GET`, sin credenciales, sin sesión y sin tokens
ajenos; las mismas peticiones que emite el cliente web público. Kongroo no
redistribuye archivos: resuelve la URL del medio y la reproduce, igual que el
navegador. Es el mismo criterio aplicado a AnimeAV1 y TioAnime.

## Historial

- 2026-11-19: investigación del frontend/backend; `/api/config` devolvía 403 y
  la misión cerró en N1 sin playback.
- 2026-11-20: se identificó `Sec-Fetch-Site: same-origin` + HTTP/2 como la regla
  real, se implementó el transporte h2 y el proxy loopback, y se verificó
  reproducción real con seek (N4).
