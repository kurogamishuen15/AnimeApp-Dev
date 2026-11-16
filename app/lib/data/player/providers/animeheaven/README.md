# AnimeHeaven

## Estado

Provider real integrado en `PlaybackProvidersModule`, con resolver MP4 propio
registrado por separado. Búsqueda, ficha, episodio, gate y probes MP4 fake
están cubiertos por tests. La reproducción externa live todavía **no** está
confirmada: `mirror-cx`, `mirror-ct` y `mirror-ck` llegaron a libmpv y los tres
mostraron error genérico de apertura/decodificación, sin cuadro de video. S0
permanece incompleta.

## Responsabilidad y estructura

Este módulo implementa el lado de AnimeHeaven del contrato. Busca título por
alias AniList exacto, asocia número de episodio con la key de gate publicada en
esa fila y solicita mirrors al endpoint `gate.php`. No elige calidades: todos
los MP4 de un episodio representan la misma calidad y se exponen como
alternativas de servidor.

| Archivo | Responsabilidad |
|---|---|
| `animeheaven_playback_provider.dart` | Búsqueda, lectura de ficha/episodio, gate público y `PlaybackSource`.
| `animeheaven_html_parser.dart` | Parser de HTML estático y allowlist de hosts exactos.
| `animeheaven_mp4_resolver.dart` | `Range` pequeño, MIME, cabecera MP4 y resultado neutral para libmpv.
| `animeheaven_http.dart` | Dio cancelable, cap de HTML a 1 MiB, cap de probe a 64 KiB, sin redirects.
| `README.md` | Contrato, límites, idioma y evidencia.

## Flujo y contratos

1. `PlaybackEpisode.animeTitles` aporta los aliases de la ficha; se prueban
   hasta tres consultas secuenciales y solo se acepta igualdad de título
   normalizado. No se hace fuzzy match que pudiera abrir otra serie.
2. `anime.php` se consulta para el título encontrado. El parser asocia el
   `gatea(key)` de cada fila solo con el número de episodio de esa fila.
3. `gate.php` recibe el key emitido por la fila como cookie `key=<value>` y el
   Referer de la ficha pública. Ese valor es del flujo público del sitio; no es
   una cookie de cuenta o un token de sesión de usuario. No se comparte con el
   CDN.
4. El parser quita comentarios HTML y decoys, exige que la query del MP4 empiece
   con la key exacta y acepta únicamente mirrors en `animeheaven.me` bajo la
   lista exacta del parser.
5. `AnimeHeavenMp4Resolver` hace un GET `Range: bytes=0-31`, no sigue
   redirects, conserva como máximo los primeros 12 bytes, valida `video/mp4` y
   `ftyp`, y cancela el resto del body.
6. El manager devuelve `ResolvedPlaybackStream` al selector/ruta existentes.
   La fuente mantiene su URI firmada efímera en memoria; no se cachea, persiste
   ni imprime.

Interfaces: `PlaybackSourceProvider` y `PlaybackVideoHostResolver`. La capa
application usa `PlaybackProviderManager`; cambios posteriores reutilizan
`PlaybackSourceSwitchService`. `MediaKitSpikeEngine` es el único reproductor.

## Idioma, hosters y formato

La referencia upstream declara contenido subtitulado, sin doblaje ni pista de
subtítulos seleccionable. El idioma del episodio real probado no quedó
confirmado; la aplicación etiqueta la fuente como
`Subtitulado (idioma no validado)`. No se afirma cobertura española ni
multilenguaje.

Allowlist del parser: `ax.animeheaven.me`, `cx.animeheaven.me`,
`cy.animeheaven.me`, `ct.animeheaven.me`, `ck.animeheaven.me`. Para One Piece
ep. 1, la respuesta live ofreció solo `cx`, `ct` y `ck`; los tres se probaron
con el player y fallaron sin frame. `ax` y `cy` no fueron publicados por esta
respuesta y no se construyeron URLs por conjetura. Cada resultado aplica solo
al episodio/solicitud probados. Los detalles están en
[`S0-REAL-PLAYBACK-REPORT.md`](../../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).

No se siguen JavaScript, redirects ni páginas de challenge; no se usan cuentas,
cookies de usuario, CAPTCHA, DRM, OAuth, firmas descifradas o impersonación.
Los redirects se clasifican como `unsupported`; 401/403, rate limit, timeout,
red y respuesta malformada se clasifican con fallos tipados. Dio usa los
timeouts definidos por el composition root.

## Dependencias

- Dio, ya presente en `app/pubspec.yaml`.
- Modelos/puertos del dominio playback.
- Manager y motor existentes.
- No se añadió dependencia ni servicio global.

La implementación es una adaptación independiente del flujo documentado por
[`AnimeHeavenProvider.kt` de Anilili, revisión `d7b80f1`, licencia MIT-0](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeHeavenProvider.kt). No se copiaron bloques de código.

## Pruebas

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/animeheaven \
  test/data/player/providers/playback_providers_module_test.dart
```

Los fakes prueban parser, exactitud de título/key, decoy, dominio permitido,
deduplicación, MIME, `ftyp`, metadatos `Content-Range`, redirects, cancelación y
manager→resolver. La cancelación también se comprueba mientras hay un body HTTP
abierto y el error TLS se clasifica como red. El test determinista no declara
servicio live operativo.

Para abrir una ventana Linux real y probar la ruta actual se usa
[`app/tool/README.md`](../../../../../tool/README.md). En ejecución de esta misión,
`flutter test` no pudo hacer requests live porque `TestWidgetsFlutterBinding`
interceptó `HttpClient` (400). El resolver HTTP validó las alternativas, pero
los tres mirrors publicados se abrieron por separado con libmpv y ninguno
presentó imagen. El propietario respondió «Autorizar manualmente en KDE»; una
captura posterior no mostró el diálogo y Wayland MCP siguió desconectado
(`Transport closed`). No se simuló entrada: el harness seleccionó los mirrors
mediante el ID explícito de entorno. Capturas y límites están en el informe S0.
