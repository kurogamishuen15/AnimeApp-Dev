# Auditoría del sistema real de proveedores y episodios — 2026-11-14

## Resultado

No se conectó ningún proveedor de streaming ni se modificó código funcional.
Las fuentes investigadas para AnimeAV1, AnimeOnline Ninja, JKAnime, TioAnime,
AnimeJara, AnimeV1 y AnimeFLV no aportaron una API con autorización verificable
para distribuir/reproducir sus enlaces multimedia. Sus avisos describen enlaces
a terceros o trasladan la responsabilidad al usuario; eso no prueba derechos de
redistribución. `anime1v-api` está bajo MIT como **código**, pero esa licencia no
otorga derechos sobre los medios que sus adaptadores extraen. Además documenta
resolución de hosts, scraping automatizado y mecanismos anti-bot, incompatibles
con el requisito del proyecto de no evadir controles.

Este es un bloqueo de evidencia/autorización para implementar reproducción real,
no una afirmación legal sobre cada título ni una limitación del motor. No se
declara operativo ni se integra ningún proveedor ficticio. El trabajo puede
reanudar con un API documentado y autorizado por los titulares/proveedor, o con
una fuente propia/licenciada y condiciones de uso comprobables.

## Investigación de referencias

| Referencia | Hallazgo comprobado | Decisión para Kongroo |
| --- | --- | --- |
| [Anilili](https://github.com/sanilili/Anilili) | Cliente Android/Kotlin; README describe Miruro y fuentes respaldadas por Anivexa, selección/fallback por prioridad, idioma sub/dub y subtítulos. El repositorio declara MIT-0. | Se adoptan como conceptos la separación por adaptador, ranking y fallback. No se copia código ni se infiere autorización de los catálogos o streams de terceros. |
| [desktoprepo1](https://github.com/sanilili/desktoprepo1) | Tauri/Rust con mpv; README describe proveedores separados, selección/fallback, HLS/DASH/MP4 y módulos WASM. Declara MIT-0. | La separación por proveedor es compatible; se reutiliza el manager Dart existente. No se copia código ni se importan fuentes/resolutores. |
| [media-index](https://github.com/sanilili/media-index) | Índice estático de títulos, episodios y mapeos de IDs de AniList/TMDB; entrega JSON por CDN y se reconstruye a diario. Declara MIT-0. | Solo serviría como metadata/crosswalk tras verificar términos y correspondencia; no contiene URLs de reproducción ni servidores. No se integra como resolver. |
| [anime1v-api](https://github.com/FxxMorgan/anime1v-api) | API de scraping con búsqueda, episodios y resolución de embeds/servidores; README describe Puppeteer, yt-dlp y extractores. Declara MIT. | No se adopta: la licencia cubre el código del repositorio, no los videos; no acredita autorización del servicio y contempla resolución/anti-bot fuera del alcance permitido. |

La referencia de AniList distingue `streamingEpisodes` como enlaces de servicios
externos. Esos enlaces no equivalen necesariamente a URI multimedia directa que
libmpv pueda abrir. La API pública tampoco constituye un proveedor de video, y
sus términos limitan ciertos usos de datos en servicios competidores; la
elegibilidad de Kongroo no se ha aprobado.

## Estado local auditado

| Módulo/ruta | Responsabilidad real | Brecha para esta tarea |
| --- | --- | --- |
| `app/lib/domain/player/providers/` | `PlaybackSourceProvider`, resultados/fallos, cancelación cooperativa y modelos de episodio/fuente/servidor/URI. | `PlaybackEpisode` solo representa `AnimeId` local + número entero; no distingue temporada, especial, película ni evidencia de equivalencia con ID externo. La validación de URL es sintáctica, no una política de confianza/SSRF. |
| `app/lib/application/player/providers/` | Registro inyectado, prioridades, orden determinista, deduplicación, circuit breaker y fallback. | `enabled` y prioridad viven en la configuración de construcción; no hay repositorio de preferencias persistentes ni UI de configuración. No crear un segundo manager. |
| `app/lib/application/player/source_switching/` | Resuelve alternativos y cambia fuente por el `SpikePlayerCoordinator`, conserva checkpoint de posición y reproducción y restaura la anterior ante fallos. | Es una capacidad de cambio, no descubrimiento inicial de anime/episodios; depende de fuentes fiables que el manager todavía no recibe. |
| `app/lib/data/player/providers/` | Solo contiene `MockPlaybackProvider` para demo/tests. | No hay adaptadores reales. Los tests existentes prueban contracts/manager con fakes, no disponibilidad ni reproducción de proveedores reales. |
| `app/lib/domain/catalog/` + `app/lib/data/anilist/` | Identidad local, crosswalk explícito, metadatos del catálogo y episodios metadata-only. | `MetadataProvider` no implementa `PlaybackSourceProvider`; los títulos/capítulos no se enlazan automáticamente con fuentes, y los metadatos no se deben convertir en enlaces reproducibles. |
| `app/lib/settings/` | Infraestructura genérica de registro/store local. | No existen claves ni repositorio registrados para preferencias de proveedor; definirlos requiere una política de producto y un contrato de episodio primero. |

### Grafo vigente

```text
UI de episodio → aplicación/coordinador → PlaybackProviderManager
                                      ↘ PlaybackSourceSwitchService → SpikePlayerCoordinator
PlaybackProviderManager → PlaybackSourceProvider (domain)
Adaptador de proveedor (data) → HTTP/SDK propio → DTO → modelos domain
AniList/catalog → MetadataProvider → metadatos; no llega a libmpv
SpikePlayerCoordinator → adaptador media_kit/libmpv
```

El flujo de catálogo a proveedor y el flujo de reproducción son actualmente
separados. Deben conectarse mediante identidad/matching explícito y evidencia de
episodio, nunca por parecido de título sin confirmación suficiente.

## Matriz de proveedores solicitados

Estados de esta auditoría: **pendiente/no integrado**. No se hicieron llamadas
de extracción ni pruebas de streams; la presencia de una página o repositorio no
se considera disponibilidad ni autorización.

| Proveedor | Idioma anunciado/objetivo | Búsqueda | Episodios | Reproducción en Kongroo | Estado y motivo |
| --- | --- | --- | --- | --- | --- |
| AnimeAV1 | Español sub/dub según adaptadores consultados | No integrada | No integrado | No | Pendiente: términos del sitio describen enlaces/terceros y no prueban licencia de distribución. |
| AnimeOnline Ninja | Español | No integrada | No integrado | No | Pendiente: no se verificó API/documentación autorizada. La fuente oficial de INDECOPI consultada registra una inspección del sitio en un expediente sobre disponibilidad presuntamente no autorizada; no se tomó esa mención como una sentencia sobre el sitio. |
| JKAnime | Español sub/dub según su sitio | No integrada | No integrado | No | Pendiente: su aviso indica enlaces alojados por terceros y no acredita derechos sobre esos archivos. |
| TioAnime | Español | No integrada | No integrado | No | Pendiente: términos del sitio no aportan autorización de redistribución ni API de reproducción autorizada. |
| AnimeJara | Español | No integrada | No integrado | No | Pendiente: el sitio se describe como índice de links de terceros; no se verificó autorización del catálogo audiovisual. |
| AnimeV1 | Español | No integrada | No integrado | No | Pendiente: identidad/API oficial y derechos de los streams no verificados. |
| AnimeFLV | Español | No integrada | No integrado | No | Pendiente: `anime1v-api` publica scraping/resolución, pero no acredita autorización de contenidos o del servicio para integrarlo. |
| Miruro, Senshi, AniBD, AniKoto, KickAssAnime, AllAnime, AnimeKai, ReAnime, AniZone, AnimeGG, AniNeko, 2DHive, RareAnimes | Varios | Referencias estudiadas parcialmente en Anilili | No integrados | No | Pendiente: ninguna autorización/API de medios fue demostrada para esta integración. |

## Hallazgos y severidad

| ID | Severidad | Hallazgo | Evidencia/efecto |
| --- | --- | --- | --- |
| PS-01 | P1 entrega bloqueada | No existe adaptador real ni se verificó un proveedor de video con autorización/documentación suficiente. | Código local: la carpeta `data/player/providers` solo tiene mock; investigación web enlazada arriba. No se puede cumplir búsqueda → fuente real sin elegir una fuente no verificada. |
| PS-02 | P2 arquitectura | Identidad del episodio es insuficiente para temporadas, especiales y películas. | `PlaybackEpisode(animeId, episodeNumber)` no porta external IDs, temporada o tipo de episodio. |
| PS-03 | P2 seguridad | `PlaybackServer` valida esquema/host, pero no restringe destinos de red privada ni valida destino/redirecciones. | Antes de aceptar URLs externas no confiables se requiere una política de salida en el adaptador; no hay entrada externa activa que actualmente la explote. |
| PS-04 | P2 configuración | Prioridad/habilitación solo se inyectan al manager; falta persistencia y UI. | `PlaybackProviderRegistration` + Settings genérico; sin claves registradas. |
| PS-05 | P3 evidencia | No hay pruebas reales de proveedor ni recorrido Fedora de episodio remoto. | Las suites actuales usan mock/fixtures. La prueba de manager ni siquiera cargó debido al desajuste local Flutter framework/engine reportado en verificaciones de abajo. |

## Validación ejecutada en esta intervención

| Comando | Resultado | Qué demuestra |
| --- | --- | --- |
| `git rev-parse --show-toplevel` | `/home/kyouma/Vídeos/PROYECTO ANIME` | Raíz confirmada. |
| `cd app && ../.ai-local/toolchains/flutter/bin/flutter test --no-pub test/domain/playback_provider_contract_test.dart test/application/playback_provider_manager_test.dart` | Exit 1 | No cargó ninguno de los dos tests: SDK aislado falla compilando Flutter `semantics.dart:164` por `SemanticsRole.slider` no cubierto (framework/engine incompatibles). No se atribuye al código de proveedor. |
| `cd app && ../.ai-local/toolchains/flutter-3.47.9/bin/cache/dart-sdk/bin/dart analyze lib/domain/player/providers lib/application/player/providers lib/application/player/source_switching lib/data/player/providers` | Exit 0, `No issues found!` | Análisis estático de los módulos existentes, no prueba de red ni reproducción. |

No se instaló dependencia, no se inició servidor externo, no se modificó código
de producción y no se hizo commit/push. Repetir tests tras reparar el mismatch
del SDK no acreditará por sí solo un proveedor real.

## Ruta segura de continuación

1. Acordar una fuente que exponga una API documentada y cuyo uso por Kongroo y
   sus enlaces multimedia esté autorizado; verificar términos, condiciones,
   atribución, límites, formatos y modo de acceso antes de codificar.
2. Si la fuente solo publica enlaces a plataformas legales, representarlos como
   enlaces externos de metadatos; no prometer reproducción directa con libmpv.
3. Definir identidad de episodio (IDs externos con procedencia, temporada, tipo,
   número/título y evidencia de match), incluyendo casos ambiguos que requieren
   selección explícita del usuario.
4. Reutilizar `PlaybackProviderManager`, `PlaybackSourceSwitchService`, el
   `SettingsStore` y los contracts existentes. Añadir un adaptador aislado solo
   después de satisfacer 1–3, con allowlist de hosts/redirects, timeout,
   cancelación, saneamiento, contract tests y fixture de medio autorizado.
5. Probar búsqueda/episodios con metadata real autorizada y reproducción con
   media real autorizado en Fedora antes de marcar cualquier proveedor como
   operativo.

## Fuentes externas revisadas (2026-11-14)

- [Anilili](https://github.com/sanilili/Anilili) y licencia MIT-0.
- [Anilili Desktop](https://github.com/sanilili/desktoprepo1) y licencia MIT-0.
- [media-index](https://github.com/sanilili/media-index), licencia MIT-0 y README de datos de metadata.
- [anime1v-api](https://github.com/FxxMorgan/anime1v-api), README, endpoints, métodos de extracción y licencia MIT.
- [AniList Media Reference](https://docs.anilist.co/reference/object/media), [API Terms](https://docs.anilist.co/guide/terms-of-use) y [Introduction](https://docs.anilist.co/guide/introduction).
- [Términos de AnimeAV1](https://animeav1.eu/pages/terminos-y-condiciones/), [DMCA de JKAnime](https://jkanime.top/dmca), [términos de TioAnime](https://tioanime.online/terminos), [DMCA de AnimeJara](https://animejara.com/dmca/).
- [Documento oficial de INDECOPI](https://www.enacom.gob.ar/multimedia/noticias/archivos/202603/archivo_20260326040053_6891.pdf): incluye acta de inspección de AnimeOnline Ninja dentro de un expediente de derecho de autor; no se infiere de esa referencia una sentencia definitiva sobre cada enlace.
