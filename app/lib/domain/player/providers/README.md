# Contratos de fuentes y reproducción

## Responsabilidad

Este módulo define modelos Dart puros que conectan la identidad de AniList o
del catálogo local con adapters de episodios, candidates de host y medios
normalizados. No importa Flutter, Dio, `dart:io`, WebView ni libmpv. El
reproductor recibe `PlayableSource` a través de los contratos de aplicación
existentes.

## Archivos y contratos

| Archivo | Tipos principales | Responsabilidad |
|---|---|---|
| `anime_identity.dart` | `AnimeIdentity` | ID local, crosswalks externos y aliases; identidad sin login. |
| `episode_source.dart` | `SourceAnimeMatch`, `EpisodeRef`, `AnimeMatchEvidence` | Mapping explícito y episodio en el namespace de un provider. |
| `playback_source.dart` | `PlaybackEpisode`, `PlaybackSource`, `SourceCandidate`, `PlayableSource` | Request de reproducción, candidato con host/modalidad/formato/expiración/disponibilidad y medio resuelto. `PlaybackServer` y `ResolvedPlaybackStream` son aliases temporales para migrar callers existentes. |
| `playback_provider_contract.dart` | `EpisodeSourceAdapter`, `PlaybackVideoHostResolver`, `PlaybackProviderResult`, fallos y cancelación | Puertos separados de búsqueda/episodios/fuentes y resolución del host. El adapter ofrece un bridge de tres fases al único `PlaybackProviderManager`. |

`PlaybackEpisode` conserva todos los IDs externos con su namespace. Su clave de
request ordena los crosswalks para que su orden de entrada no cree cachés
duplicadas. `EpisodeSourceAdapter` define `searchAnime(AnimeIdentity)`,
`listEpisodes(SourceAnimeMatch)` y `findEpisodeSources(EpisodeRef)`. Su bridge
heredado implementa el contrato agregado que hoy consume el manager, sin crear
otro registry. El match solo sigue automáticamente si comparte un ID externo
del namespace correcto o un título exacto normalizado; `fuzzy` y `unknown`
quedan rechazados para reproducción.

Cada `SourceCandidate` mantiene `hostId`, modalidad (`media`, `embed`,
`redirect`), formato declarado (`mp4`, `hls`, `dash`, `webm` o `unknown`),
idioma, calidad, etiqueta de presentación, disponibilidad (`unknown`, `listed`,
`transportResponded`, `playable`), procedencia y expiración. Solo candidatos
`media` no vencidos se ofrecen a un resolver. Variantes de calidad pueden ser
modeladas como alternativas del mismo host; la UI no debe contarlas como
servidores distintos.

`PlaybackSource` también conserva por separado idioma del audio/subtítulo,
tipo de doblaje y etiqueta lingüística declarada por el proveedor. Una
etiqueta no se convierte en `latinSpanish` o `castilianSpanish` salvo que el
catálogo la identifique explícitamente. `PlayableSource` conserva formato,
cabeceras públicas permitidas, etiquetas de origen y disponibilidad; una
etiqueta no se promueve a reproducción verificada sin evidencia de decodificación
y un frame real. Nunca se registran URLs temporales en representaciones de
diagnóstico.

El resultado tipado distingue fallos de red, timeout, ausencia de ID/episodio/
fuentes, denegación, embed no compatible, vencimiento, manifiesto inválido,
decoder, bloqueo y cancelación. Errores de decodificación se originan en la
capa de player y no se atribuyen al provider automáticamente.

## Seguridad y plataformas

`PlaybackRequestHeaders` admite Referer HTTPS público, Origin HTTPS público
sin ruta y User-Agent validado. Rechaza valores con credenciales, caracteres de
control y destinos locales. No transporta cookies ni Authorization. Los
adapters no deben inventar tokens ni eludir autenticación, DRM, CAPTCHA o WAF.
El dominio no requiere SDK por sistema operativo. Los adapters concretos de red,
WebView o storage se inyectan en `data/`. Linux tiene análisis y pruebas de
dominio; Android y Windows siguen sin build/runtime validado. La neutralidad de
los contratos no se presenta como compatibilidad ejecutada.

## Pruebas y dependencias

No añade paquetes. Pruebas offline desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/domain/episode_source_adapter_test.dart \
  test/domain/playback_provider_contract_test.dart
```

Los casos prueban las fases en orden, cruce exacto, rechazo fuzzy, cancelación,
modelos normalizados y contrato de cabeceras. No prueban un servidor externo ni
la reproducción en libmpv. El estado de providers está en
[`data/player/providers`](../../../data/player/providers/README.md) y la auditoría
en [`S0-S`](../../../../../docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

## Subtítulos publicados con el episodio

`ProviderSubtitle` describe VTT HTTPS público publicado por la misma fuente:
ID, URI efímera, etiqueta, idioma declarado y default. `PlaybackSource` y
`PlayableSource` lo conservan en una lista inmutable de hasta 32 entradas con
IDs únicos. No es búsqueda de subtítulos ni prueba de sincronía o disponibilidad.
El dominio rechaza URI locales/privadas, credenciales, fragmentos y documentos
que no sean VTT. Una etiqueta sub/dub no se convierte en un ISO de audio.
