# Auditoría S0 — resolutores de hosts de video

> **Corte histórico:** este informe examina el prototipo común de hosts antes
> de su retirada. No describe resolutores registrados actualmente; ver la
> [auditoría de limpieza posterior](S0-provider-cleanup-followup-audit-2026-11-15.md).

**Fecha:** 2026-11-15<br>
**Alcance:** cambios locales de S0 en contratos AnimeProvider/VideoHostResolver,
manager, transporte público HTTP, hosts MP4/HLS, paso a media_kit/libmpv y
documentación.<br>
**Resultado:** implementación focalizada y pruebas deterministas correctas; S0
continúa **bloqueada para aceptación** porque no se confirmó un cuadro de video
externo. No se recomienda cerrar S0 ni G1.

## Resumen ejecutivo

La responsabilidad queda separada en los contratos existentes: proveedores de
anime encuentran episodios y servidores, un resolver compartido valida enlaces
públicos y el `MediaKitSpikeEngine` existente conserva la reproducción. El
resolver se registra una vez en `PlaybackProviderManager`; no se creó un segundo
player. Los adaptadores AnimeAV1, TioAnime y AnimeGG ya no duplican resolución
de host.

La pasada live comprobó cada una de las cinco alternativas de TioAnime una vez.
AnimeGG resolvió una fuente pública y libmpv avanzó 5311 ms, pero solo reportó
codec de audio y no dimensiones de video. AnimeAV1 fue denegado y AniZone
respondió 404/419. Ningún servidor produjo video externo verificado. FileStream,
Bee y Goma no aparecieron en las páginas/alternativas revisadas; no hay URLs con
las cuales implementar o probar sus resolutores.

## Entorno y versiones

- Proyecto: `/home/kyouma/Vídeos/PROYECTO ANIME`; rama `main`;
  HEAD de referencia `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
- Toolchain aislado dentro de `.ai-local/toolchains/flutter`: Flutter
  `3.50.0-0.4.pre`, revisión `368ac9e40b`, Dart `3.14.0-315.3.beta`, Linux x64.
- Dependencias fijadas en `app/pubspec.lock`: Dio `5.11.1`, media_kit `1.2.6`.
  El lockfile no cambió. No se actualizó el SDK global.
- No se hizo commit, stage, push ni CI completa.

## Arquitectura y recorrido inspeccionados

- `domain/player/providers/playback_provider_contract.dart:119` define
  `PlaybackVideoHostResolver` separado del proveedor de episodios.
- `domain/player/providers/playback_source.dart` contiene `PlaybackServer` y el
  `Referer` público permitido como contexto tipado.
- `application/player/providers/playback_provider_manager.dart:288-313,388-393`
  selecciona un resolver registrado por host y verifica la identidad de source,
  provider y server antes de aceptar el resultado.
- `data/player/providers/video_hosts/public_media_video_host_resolver.dart:13-89`
  extrae solo URLs estáticas MP4/HLS desde hosts configurados, valida origen y
  entrega URI y headers al contrato existente. No ejecuta JavaScript ni resuelve
  desafíos.
- `data/player/providers/public_site_http.dart:186-337` hace GETs streaming
  acotados, procesa redirecciones manualmente, usa Range para MP4 con un único
  GET ordinario ante 405/416/5xx y verifica HLS con GET ordinario y firma
  `#EXTM3U`.
- `data/player/providers/public_site_http.dart:435-500` valida hasta 128
  referencias HTTPS HLS, allowlist y DNS; rechaza SAMPLE-AES.
- `data/player/providers/playback_providers_module.dart` comparte el cliente
  Dio y registra una instancia del resolver estático para el manager actual.
- `data/player/engine/media_kit_spike_engine.dart` recibe la URI y cabeceras del
  flujo actual; la prueba loopback confirmó forwarding de Referer al abrir y
  después de Stop→Play.

## Inventario live y evidencia

| Host | Fuente que lo ofreció | Resultado del corte actual | Estado |
|---|---|---|---|
| Zilla (`player.zilla-networks.com`) | AnimeAV1, Shingeki no Kyojin ep. 1 | `unauthorized`; sin URI para libmpv. | `RESOLVING` |
| Mega (`mega.nz`) | TioAnime ep. 1 | `unsupported`; no medio estático público reconocido. | `RESOLVING` |
| StreamSB (`embedsb.com`) | TioAnime ep. 1 | Timeout en la consulta acotada. | `RESOLVING` |
| YourUpload (`yourupload.com`) | TioAnime ep. 1 | En este recheck: `network`; una corrida anterior sí obtuvo URI, pero libmpv no avanzó y reportó error. | `RESOLVING` |
| OK.ru (`ok.ru`) | TioAnime ep. 1 | `unsupported`; HTML sin endpoint estático reconocido. | `RESOLVING` |
| Netu (`hqq.tv`) | TioAnime ep. 1 | `unsupported`; HTML sin endpoint estático reconocido. | `RESOLVING` |
| `vidcache.net` | AnimeGG, One Piece ep. 1 | URI aceptada; libmpv avanzó `5311 ms`, codec de audio presente, dimensiones de video nulas; prueba falló por falta de video. | `RESOLVING` |
| `seiryuu.vid-cdn.xyz` | AniZone, HLS anunciado | HTTP 404 tanto a Range como a GET ordinario; acción Livewire pública respondió 419. No se reintentó ni eludió. | `BLOCKED_EXTERNAL` |
| CatStream | KickAssAnime, One Piece ep. 1 | Player 200 sin URI/manifiesto estático reconocible; no se aplicó extracción de JS, firma o AES para rutas legacy. | `BLOCKED_EXTERNAL` |
| FlixCloud | ReAnime | La implementación upstream inspeccionada extrae una máscara XOR, obtiene token/stream mediante `enc-dec.app` y transforma segmentos en un proxy local. No se comprobó una ruta directa del host sin esa transformación ni se probó live. | `INVESTIGATING` |
| MegaPlay | 2DHive | Fuente previa identifica etapa crypto; no se obtuvo URI directa ni se intentó descifrar. | `INVESTIGATING` |
| FileStream, Bee, Goma | Ninguna fuente en el material revisado | No observados. Sin enlace, formato ni host exacto para probar. No se concluye que estén ausentes de todo episodio. | Sin evidencia |

AnimeGG publicó cinco filas subbed/dubbed y de calidad. Son variantes de fuente,
no cinco servidores. En este corte se probó una variante preferida.

## Hallazgos

### S0-VH-P1-01 — playback externo de video no demostrado — ABIERTO

- **Evidencia:** informe de misión, secciones “Revisión S0 enfocada en hosts de
  video” y matriz; prueba live AnimeGG
  `app/test/data/player/providers/public_playback_provider_test.dart:924-1048`;
  TioAnime en `:728-807`. Los dos smokes actuales terminaron con exit 1 porque
  no hubo dimensiones de video ni host que reprodujera. AniZone y AnimeAV1
  tampoco entregaron medio usable.
- **Reproducción:** desde `app/`, ejecutar los dos comandos live enumerados en
  `TESTING.md` con sus variables opt-in. AnimeGG reporta posición 5311 ms y
  dimensiones `nullxnull`; TioAnime informa cinco hosts y cero streams.
- **Consecuencia:** no se cumple la regla de finalización de S0; no contar URI,
  audio aislado, HTTP 200 ni posición sin video como éxito.
- **Acción:** esperar un enlace público válido de uno de los hosts ya observados
  o una fuente nueva distinta; confirmar primer cuadro/dimensiones, avance, audio
  y seek mediante el player existente antes de pasar el gate.
- **Regresión necesaria:** mantener pruebas fixtures/resolver y un smoke live
  opt-in que falle si no obtiene dimensiones y avance. No falsificarlo con fakes.

### S0-VH-P2-01 — cobertura de FileStream/Bee/Goma sin fuente — ABIERTO

- **Evidencia:** cinco alternativas de TioAnime y las fuentes examinadas de
  AnimeAV1, AnimeGG y AniZone no los listan.
- **Reproducción:** lectura de las alternativas conservadas y sus READMEs; no
  existe endpoint observado para lanzar una petición legítima.
- **Consecuencia:** el inventario no cubre esos nombres en otros episodios o
  fuentes. No se conoce su protocolo ni si admiten MP4/HLS público.
- **Acción:** añadirlos al inventario solo cuando una respuesta pública de un
  episodio identifique su host exacto. Entonces reutilizar el contrato compartido
  y probarlo sin sesión ni bypass.
- **Límite:** esto es falta de evidencia, no un defecto del resolver.

### S0-VH-P2-02 — protocolos especializados no producen una URI pública estática — ABIERTO

- **Evidencia:** el episodio público de KickAssAnime expuso CatStream, pero su
  player no reveló URI/manifiesto estático; la referencia upstream señala
  extracción dinámica y firma/AES en rutas legacy. La fuente ReAnime de Yuzono
  muestra una máscara XOR extraída del script del host, solicitudes token/stream
  a `enc-dec.app` y decodificación XOR de segmentos servidos por un proxy local
  ([flujo de resolución](https://raw.githubusercontent.com/yuzono/anime-extensions/master/src/en/reanime/src/eu/kanade/tachiyomi/animeextension/en/reanime/ReAnime.kt),
  [proxy de segmentos](https://raw.githubusercontent.com/yuzono/anime-extensions/master/src/en/reanime/src/eu/kanade/tachiyomi/animeextension/en/reanime/FlixProxyServer.kt)).
  Esto no demuestra una ruta directa HLS/MP4 publicada por FlixCloud que libmpv
  pueda abrir sin esa transformación. La fuente previa de 2DHive reporta una
  etapa crypto para MegaPlay.
- **Reproducción:** la página pública de CatStream devolvió 200 sin el marcador
  de manifiesto/URI estática que reconoce la extracción inspeccionada. ReAnime y
  2DHive no recibieron petición de extracción en esta auditoría.
- **Consecuencia:** no se construye un resolver reutilizable de URL estática con
  esta evidencia; no se intentaron pasos criptográficos ni proxy.
- **Acción:** mantener estos hosts en inventario, no en allowlist activa, hasta
  que exista una ruta directa documentada que no necesite evadir controles.
- **Estado:** falta de evidencia/cobertura, no defecto del resolver común. En
  FlixCloud no se estableció si la transformación upstream corresponde a una
  protección de acceso; se conserva `INVESTIGATING` y no se implementa mientras
  no exista evidencia de un flujo público soportado que respete el límite de no
  evadir controles.

### S0-VH-P2-03 — validación de destino no fija la red que usa libmpv — RIESGO

- **Evidencia:** el transporte consulta allowlist/DNS antes de devolver una URI
  (`public_site_http.dart:204-208,482-500`), mientras el player nativo abre la
  URI por su propio cliente HTTP. El propio código advierte que la comprobación
  DNS no fija la resolución posterior.
- **Reproducción:** no se ejecutó un servidor controlado que cambie DNS o
  redireccione una referencia HLS permitida a una dirección privada. Este riesgo
  es una inferencia de la separación entre el probe Dart y el cliente nativo, no
  un exploit observado.
- **Consecuencia:** un host externo cambiante podría hacer que el cliente nativo
  solicite un destino diferente al comprobado; el alcance incluye HLS con
  referencias cargadas luego por libmpv.
- **Acción recomendada:** antes de tratar entradas remotas como no confiables en
  general, determinar si la versión de libmpv/media_kit permite restringir
  redirects/protocolos o si hace falta un transporte intermedio seguro. No se
  amplió esta misión para introducir proxy o dependencia adicional.
- **Prueba necesaria:** fixture local con redirect a destino no permitido y
  verificación de que ninguna solicitud sale del límite permitido.

## Pruebas ejecutadas en esta auditoría

| Comprobación | Resultado |
|---|---|
| `flutter test --no-pub test/data/player/providers/public_playback_provider_test.dart test/application/playback_provider_manager_test.dart test/domain/playback_provider_contract_test.dart` | Exit 0; 41 pasaron, 3 smokes live omitidos por defecto. |
| `flutter test --no-pub test/player/provider_playback_route_test.dart test/player/spike_player_coordinator_test.dart` | Exit 0; 35/35. |
| Integración `KONGROO_TEST_HTTP_REFERER=1 ... media_kit_spike_integration_test.dart --plain-name 'libmpv preserves a public Referer across open and replay after Stop'` | Exit 0, 1/1. Hubo 3 requests loopback; `Referer` esperado observado; avance local 43 ms. No es fuente externa. |
| `flutter analyze --no-pub` | Exit 0; sin issues. |
| `dart analyze lib test` | Exit 0; sin issues. |
| `dart format --output=none --set-exit-if-changed` sobre los 3 Dart del resolver/test | Exit 0 después de formatear el test modificado. |
| TioAnime live, cinco alternativas | Exit 1 de aceptación; Mega/OK.ru/Netu unsupported, StreamSB timeout, YourUpload network. No hubo playback. |
| AnimeGG live, variante preferida | Exit 1 de aceptación; URI `vidcache`, avance 5311 ms, audio detectado y sin dimensiones de video. |
| `git diff --check` | Exit 0. |

No se ejecutaron CI completa, build release, prueba de ventana gráfica,
reproducción AniList→player completa con un stream funcional, medición de RAM/CPU
en reproducción externa ni el test de redirect nativo señalado como riesgo.

## Documentación y revisión adversarial

Se actualizaron README de video_hosts, AnimeAV1, TioAnime y AnimeGG; el informe
S0, STATUS, HANDOFF, PROGRESS, TESTING, PROJECT_STATE, AI_HANDOFF, MODULE_INDEX,
RESEARCH_INDEX y DECISIONS. La pasada adversarial fue realizada por el mismo
coordinador después de revisar contratos, orden de fallback, límites de red,
cancelación y destrucción de cuerpos HTTP; no fue revisión independiente.

## Continuación

S0 permanece activa y bloqueada para aceptación por `S0-VH-P1-01`. No repetir
hosts que dieron denegación, timeout o ausencia de medio, salvo evidencia nueva.
Continuar con un host diferente solo al aparecer en una fuente pública de
episodio; no ampliar catálogos sin ese motivo técnico. No commit ni push.

## Fuentes técnicas consultadas

- [Dio 5.11.1](https://pub.dev/packages/dio/versions/5.11.1) y
  [ResponseType](https://pub.dev/documentation/dio/latest/dio/ResponseType.html),
  para respuestas streaming y redirects manuales. El lockfile fija Dio 5.11.1.
- [media_kit 1.2.6](https://pub.dev/packages/media_kit/versions/1.2.6),
  referencia para pasar `httpHeaders` al recurso del player; el lockfile fija
  esta versión.
- Fuentes públicas Aniyomi/Yuzono revisadas el 2026-11-15:
  [AnimeAV1](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeav1/src/eu/kanade/tachiyomi/animeextension/es/animeav1/AnimeAv1.kt),
  [TioAnime](https://github.com/yuzono/anime-extensions/blob/master/src/es/tioanimeh/src/eu/kanade/tachiyomi/animeextension/es/tioanimeh/TioanimeH.kt)
  y [AnimeGG](https://github.com/yuzono/anime-extensions/blob/master/src/en/animegg/src/eu/kanade/tachiyomi/animeextension/en/animegg/AnimeGG.kt).
  Se consultaron para contrastar hosts y comportamiento público; no se copió
  código ni se usó extracción de desafíos, firmas o descifrado.
- La [fuente ReAnime de Yuzono](https://raw.githubusercontent.com/yuzono/anime-extensions/master/src/en/reanime/src/eu/kanade/tachiyomi/animeextension/en/reanime/ReAnime.kt)
  y su [proxy local](https://raw.githubusercontent.com/yuzono/anime-extensions/master/src/en/reanime/src/eu/kanade/tachiyomi/animeextension/en/reanime/FlixProxyServer.kt),
  consultados el 2026-11-15, muestran máscara XOR, token/stream vía `enc-dec.app`
  y transformación on-the-fly de segmentos. No se ejecutó ni adaptó ese flujo;
  no se verificó una URL directa servida sin la transformación.
- El [issue upstream AnimeAV1 #1111](https://github.com/yuzono/anime-extensions/issues/1111)
  reporta 403 en segmentos HLS asociado a `Sec-Fetch-Site`. No se emuló ese
  encabezado ni se intentó superar el rechazo.
