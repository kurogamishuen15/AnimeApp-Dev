# Proveedores de reproducción

## Estado actual

El runtime registra **un provider implementado**, AnimeHeaven, y un resolver
reutilizable específico para sus mirrors MP4. Aún hay **cero providers con
reproducción externa confirmada**: los tres mirrors publicados para One Piece
ep. 1 llegaron por separado al player existente, pero todos mostraron error de
apertura/decodificación y no presentaron imagen. S0 sigue abierta.

La limpieza S0-A de Miruro, AnimeAV1, TioAnime, AnimeGG y el resolver genérico
anterior se conserva como historia; sus evidencias no equivalen a runtime
actual. Ver el [informe S0](../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md),
las [auditorías S0](../../../../../docs/ai-system/audits/) y el [handoff](../../../../../docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md).

## Arquitectura y flujo

| Capa | Componente | Responsabilidad |
|---|---|---|
| Catálogo/fuentes | [`animeheaven/`](animeheaven/README.md) | Busca por título AniList exacto, mapea episodio y pide sus alternativas MP4 al flujo público del proveedor. |
| Hosts | `AnimeHeavenMp4Resolver` en `animeheaven/` | Permite una lista exacta de mirrors HTTPS, comprueba MIME/cabecera MP4 y cancela el body del probe tras 12 bytes. |
| Orquestación | `PlaybackProviderManager` | Ordena alternativas, valida identidad, conserva errores y entrega fallback al caller. |
| Cambio de fuente | `PlaybackSourceSwitchService` | Pide al coordinator existente que cambie de candidato y restaure el estado cuando corresponde. |
| Motor | `MediaKitSpikeEngine` / libmpv | Único dueño del Player y la superficie de video; no consulta proveedores. |

`PlaybackProvidersModule.open()` posee el cliente Dio y registra el provider y
resolver separados. `close()` libera el transporte y es idempotente. La ficha
construye `PlaybackEpisode` con ID AniList, aliases y número; el selector abre
`ProviderPlaybackRoute`. No se crea un segundo sistema de reproducción.

## Carpetas y archivos principales

- `animeheaven/animeheaven_playback_provider.dart`: búsqueda exacta, catálogo,
  gate público y construcción de `PlaybackSource`.
- `animeheaven/animeheaven_html_parser.dart`: parser puro de búsqueda,
  episodios, keys gate y mirrors permitidos; no ejecuta scripts.
- `animeheaven/animeheaven_mp4_resolver.dart`: comprobación host/MIME/prefix y
  conversión a `ResolvedPlaybackStream`.
- `animeheaven/animeheaven_http.dart`: límites de bytes, cancelación de Dio,
  tiempo delegado a BaseOptions y rechazo de redirects.
- `playback_providers_module.dart`: composition root y ciclo de vida del HTTP.
- `mock/`: fixtures de contrato; no se registra en runtime.

## Protocolo, idiomas y límites

El recorrido actual usa GET ordinarios: búsqueda `search.php`, ficha
`anime.php`, lista de episodios y `gate.php`. La página pública del episodio
publica una key corta para el flujo de gate; el provider la envía solamente
como cookie `key` a `gate.php`. No se envían cookies de cuenta, autorización,
challenge ni datos del navegador. Las URLs de video que contienen tokens de
tiempo limitado se mantienen solo en memoria y no se escriben en logs ni en
caché.

El alcance implementado es MP4 progresivo y una calidad por episodio. Los
hosts se restringen por nombre completo a `ax`, `cx`, `cy`, `ct` y `ck` bajo
`animeheaven.me`. Cada mirror es alternativa del mismo encode, no una calidad.
Los GET del provider y el probe de media no siguen redirecciones. El probe pide
`Range: bytes=0-31`, conserva como máximo el prefijo mínimo y valida `video/mp4`
más `ftyp`. En el probe live previo, la respuesta fue `206 video/mp4` pero el
`Content-Range` describió el archivo entero pese a pedir un byte; el resolver
no confía en ese encabezado y el player sigue siendo la prueba decisiva.

La referencia upstream fijada de AnimeHeaven en Anilili declara contenido
subtitulado sin doblaje ni selección de subtítulo. El idioma de subtítulo del
episodio probado aún no se validó dentro de Kongroo, por lo que la UI no lo
etiqueta como español ni multilenguaje. Se adaptó el protocolo y se escribió
un parser independiente; no se copió el código upstream. Referencia/licencia:
[AnimeHeavenProvider.kt en Anilili, revisión `d7b80f1`, MIT-0](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeHeavenProvider.kt).

## Dependencias e interfaces

- Dio ya está en `app/pubspec.yaml`; no se añadió paquete.
- Domain: `PlaybackSourceProvider`, `PlaybackVideoHostResolver`,
  `PlaybackEpisode`, `PlaybackSource`, `PlaybackServer` y
  `ResolvedPlaybackStream`.
- Application: manager, breakers y `PlaybackSourceSwitchService` existentes.
- Player: `ProviderPlaybackRoute` y engine media_kit/libmpv existentes.
- Sin cliente, widget, cache o engine paralelo.

## Pruebas

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/animeheaven \
  test/data/player/providers/playback_providers_module_test.dart
```

Los tests fake cubren búsqueda exacta, episodio/key, eliminación de source
decoy en comentarios, allowlist, duplicados, redirects, MP4/MIME, Range con
metadatos anómalos, cancelación y paso por manager/resolver. No prueban
disponibilidad externa ni decodificación del sitio.

Para el smoke real con ventana Linux, usar
[`app/tool/README.md`](../../../../../tool/README.md). No usar `flutter test`
para requests live: `TestWidgetsFlutterBinding` intercepta `HttpClient` y
devuelve 400. El primer intento GUI se documenta en
[`S0-REAL-PLAYBACK-REPORT.md`](../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md);
hubo ventana libmpv pero no un cuadro visible confirmado.
