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
| `playback_source.dart` | `PlaybackEpisode`, `PlaybackSource`, `SourceCandidate`, `PlayableSource` | Request de reproducción, candidato con host/modalidad/expiración y medio resuelto. `PlaybackServer` y `ResolvedPlaybackStream` son aliases temporales para migrar callers existentes. |
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
`redirect`), idioma declarado/`unknown`, calidad, procedencia y expiración.
Solo candidatos `media` no vencidos se ofrecen a un resolver. Un
`PlayableSource` conserva formato (`mp4`, `hls`, `dash` o `unknown`), cabeceras
públicas, procedencia y expiración. Nunca registra URLs temporales en sus
representaciones de diagnóstico.

El resultado tipado distingue fallos de red, timeout, ausencia de ID/episodio/
fuentes, denegación, embed no compatible, vencimiento, manifiesto inválido,
decoder, bloqueo y cancelación. Errores de decodificación se originan en la
capa de player y no se atribuyen al provider automáticamente.

## Seguridad y plataformas

`PlaybackRequestHeaders` solo admite un `Referer` HTTPS de origen público,
validado; no transporta cookies, Authorization ni cabeceras arbitrarias. Los
adapters no deben inventar tokens ni eludir autenticación, DRM, CAPTCHA o WAF.
El dominio no requiere SDK por sistema operativo. Los adapters concretos de red,
WebView o storage se inyectan en `data/`; Linux, Android y Windows aún no tienen
validación completa en este módulo.

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
