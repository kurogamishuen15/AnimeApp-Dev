# Catálogo Miruro

## Responsabilidad y estado

`MiruroCatalogPlaybackProvider` adapta el catálogo público REST de Miruro al
contrato `EpisodeSourceAdapter` ya consumido por `PlaybackProviderManager`.
Mapea un ID de AniList exacto, descubre el título y episodios, pide el listado
de fuentes del episodio y normaliza streams HTTPS directos. No busca por fuzzy
title, no interpreta páginas iframe y no crea un player. El fallback y el
reproductor continúan siendo los existentes.

Está registrado por defecto como `miruro-catalog` versión `1.0.0`, y puede
desactivarse con `KONGROO_ENABLE_MIRURO=0`. A 2026-11-17 sus GET públicos para
configuración e identificación del título de AniList 100240 respondieron 403
Cloudflare en dos orígenes, antes de obtener episodios o media. El adapter
clasifica el 403 como denegación y no reintenta otros mirrors. Por eso el módulo
está implementado y cubierto offline, pero no se declara disponible ni
reproducible en vivo.

La revisión de transporte del 2026-11-17 corrigió un fallo adicional: el lector
HTTP intentaba interpretar el catálogo binario como UTF-8 antes de entregarlo
al decoder XOR+gzip. Ahora conserva los bytes y adjunta el Referer HTTPS del
origen del catálogo en cada petición. La prueba binaria atraviesa HTTP,
provider, manager y resolver. El manager real sigue recibiendo HTTP 403 en la
identificación de AniList 100240. La corrección interna está verificada con
pruebas y no establece disponibilidad del servicio.
[Evidencia de la corrección](../../../../../../docs/ai-system/audits/OC04-BINARY-TRANSPORT-audit-2026-11-17.md).

## Archivos y dependencias

| Archivo | Función |
|---|---|
| `miruro_catalog_api.dart` | GET HTTPS ordinario en orígenes exactos; lee JSON o el payload de catálogo XOR+gzip con límite de descompresión; reintenta solo red/5xx. |
| `miruro_catalog_parser.dart` | Parser Dart puro para config, ID, episodios, tracks, servidores y streams directos. |
| `miruro_catalog_playback_provider.dart` | Matching por ID AniList, fases de episodios/fuentes, TTL/LRU internos y bridge al manager. |
| `README.md` | Estado, contratos, límites, licencia y comandos de prueba. |

Usa `Dio` existente mediante `PublicPlaybackHttp`; el composition root comparte
y cierra una instancia. No agrega paquetes. Las cachés internas se limitan a
128 títulos y dos listas de episodios; los TTL son 30 minutos para config/título
y cinco minutos para episodios. Cuerpos HTTP quedan limitados por el transporte
a 2 MiB por defecto, 8 MiB como máximo; el stream gzip también limita su
resultado expandido a 8 MiB.

## Endpoints adaptados

Los endpoints se componen bajo `/api/` y usan los campos documentados por la
implementación suministrada de Anilili:

- `GET /api/config`
- `GET /api/v1/anime?anilist_id_in=<id>&limit=100`
- `GET /api/v1/anime/<title-id>/episodes?limit=10000&cursor=<cursor>`
- `GET /api/v1/anime/<title-id>/episodes/<number>/play`

La pantalla de detalle ya obtiene el índice de episodios por Kitsu. Al pulsar
un episodio, el adapter consulta directamente el endpoint de `play` para ese
número, evitando descargar el índice completo en cada reproducción. El método
`listEpisodes` sigue disponible para los flujos que requieren enumerarlo; pagina
con cursor y limita el total a 20.000 episodios.

El catálogo puede devolver JSON sin comprimir o bytes decodificados mediante
XOR y gzip. La transformación se considera formato de catálogo, no protección
de acceso. Los datos del endpoint `play` pueden contener varios providers y
servidores: las calidades se agrupan por host y se elige la más alta declarada,
no se presentan como servidores independientes. Solo se emiten streams directos
HTTPS públicos con formato conocido (MP4/HLS/DASH/WebM). Las entradas iframe
quedan fuera.

Los idiomas de audio/subtítulo y tipo de doblaje se propagan solo cuando el
catálogo los declara explícitamente; el texto original del proveedor se guarda
por separado. `listed` significa que la fuente aparece en el catálogo, no que
el transporte o la reproducción hayan sido comprobados.

## Seguridad y manejo de errores

- Sin cookies, Authorization, tokens, sesión, UA de navegador o resolución de
  challenges. Los 4xx —incluido 403— detienen el intento. Se prueban hasta tres
  orígenes solo para errores de red o 5xx.
- Solo orígenes Miruro HTTPS exactos, puerto 443 y rutas con formato acotado.
- Solo se preserva un Referer HTTPS público sin query/fragmento si está declarado.
- No se siguen redirects hacia hosts no aprobados, no se obtiene DNS ni se
  interpreta HTML/JavaScript. Los embeds son `unsupported` para esta integración.
- Errores de red, rate limit, denegación, respuesta inválida y cancelación se
  convierten al resultado tipado del dominio; no se registran URLs temporales.

## Pruebas y procedencia

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/miruro_catalog_provider_test.dart \
  test/data/player/providers/playback_providers_module_test.dart
```

Los tests usan fixtures JSON, payload XOR+gzip y adaptadores HTTP fake. Cubren
mapping por ID, episodios, selección/calidad, idioma/doblaje, rechazo de embed,
límite de expansión, cancelación, reintento de 5xx y parada ante 403. La prueba
del manager recibe título, configuración y fuentes como XOR+gzip a través del
adaptador HTTP. La suite de transporte también usa loopback para comprobar
bytes no UTF-8, rechazo de esos bytes en lectura textual y ausencia de fuga
de Referer entre peticiones. No
demuestran que el servicio externo responda ni que libmpv pueda decodificar una
fuente.

Se adaptó la forma del protocolo y sus modelos del código de Anilili que el
propietario proporcionó; no se copió runtime Kotlin/Android, WebView,
Cloudflare/challenge, cookies, clients de navegador ni resolutores de
Anivexa/AniChan. La referencia upstream y el aviso MIT-0 están en
[`docs/third-party/ANILILI-MIT-0.md`](../../../../../../docs/third-party/ANILILI-MIT-0.md).
El [informe de migración](../../../../../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md)
separa la evidencia de código de la disponibilidad real del servicio.
