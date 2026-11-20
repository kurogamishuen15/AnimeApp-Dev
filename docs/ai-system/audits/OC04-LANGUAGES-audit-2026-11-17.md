# OC-04 · Variantes de audio y subtítulos publicados

Fecha: 2026-11-17. Alcance: ampliar el MegaPlay/bee funcional conservando
AniList/Kitsu, manager, resolver directo, media_kit/libmpv y progreso.
No se cierra la petición completa de audio y subtítulos en tres idiomas:
el doblaje español continúa sin una fuente accesible demostrada.

## Implementación

- Un adapter MegaPlay parametrizado por `sub`/`dub`, registrado como `megaplay`
  y `megaplay-dub`, con el mismo resolver directo. Son variantes de contenido,
  no dos extractores para un host. Se mantiene el cruce exacto AniList/episodio.
- Transporte compartido por ambas variantes: `Retry-After` del mismo origen
  detiene la segunda petición. No se añade emulación, cookies ni otro motor.
- `ProviderSubtitle` conserva los VTT publicados en la respuesta del episodio.
  Valida HTTPS público, formato, etiquetas, máximo 32 entradas e IDs únicos.
  El resolver conserva esos datos; el composition root los limita a los medios
  autorizados y rechaza catálogos contradictorios para una misma URI.
- El menú existente selecciona VTT mediante `SubtitleTrack.uri` de media_kit
  1.2.6. No se amplía la importación manual, que sigue aceptando archivos locales.
  Cambiar fuente/Stop invalida IDs de menú antiguos; Stop→Play restaura catálogo.
- `sub`/`dub` se muestran como variante anunciada. El backend no declara ISO de
  audio, por lo que `audioLanguage` permanece unknown. Las etiquetas English,
  Spanish, Japanese y Portuguese sí identifican idiomas de subtítulos; no se
  infiere doblaje español a partir de Spanish en una pista de texto.

No hay dependencias nuevas ni código copiado de AnikenTV o Zangetsu.
La adaptación continúa bajo el aviso MIT-0 ya conservado de Anilili.

## Evidencia real

| Cadena | Resultado actual |
| --- | --- |
| Tokyo Ghoul:re, AniList 100240, ep. 9, `dub` | Embed y sources 200; HLS H.264/AAC abre en ffprobe. Ventana real desde main(), textura 1920×1080, subtítulos ingleses visibles, pausa/seek y progreso. Duración 1452090 ms; guardó 23356 ms; retorno a ficha; test aprobó en 31 s. |
| Attack on Titan, AniList 16498, ep. 1, `sub` + Spanish | Embed/sources/VTT 200. Ventana 1920×1080, elección Spanish en diálogo, `sid=1`, `sub-visibility=yes`, `sub-text` no vacío y captura con texto español superpuesto. Duración 1556449 ms. Última prueba reanudó desde 68651 ms, buscó hacia delante y luego volvió a 43000 ms, guardó 68818 ms y regresó a ficha; aprobó en 34 s. |
| Variante original japonesa de Tokyo Ghoul:re 9 | Evidencia previa de vídeo visible conservada; la nueva variante sub funciona también en Attack on Titan 1. No se certifica el idioma acústico mediante tags: ambos HLS omiten language en el stream AAC. |
| Audio español de AnimeAV1 | Su adapter mantenido declara DUB latino y cruce MAL. El único GET ordinario de catálogo durante esta sesión devolvió 403; detenido sin reintentos ni bypass. No hay medio o vídeo español confirmado. |

Las capturas del compositor se inspeccionaron visualmente:
`.ai-local/languages/kongroo-dub-en.png` (texto inglés y variante dub) y
`kongroo-sub-es-caption.png` (texto español sobre vídeo). La primera captura
española cayó en un intervalo sin diálogo; se conservó otra con texto visible.
Los logs finales están en `gui-dub.log` y `gui-sub-es-final.log`.
Las URLs efímeras y la base de progreso aislada permanecen ignoradas por Git.
No se modifica la base personal del usuario.

La prueba GUI usa `integration_test` desde main() y eventos del framework en la
ventana Linux real; no equivale a entrada física del ratón ni certifica escucha
humana del audio. La variante dub corresponde a la ruta de doblaje de la
referencia inglesa; la identificación acústica del idioma no se automatizó.

## Revisión y pruebas

Auditor independiente, solo lectura, detectó tres puntos corregidos:

1. **LANG-01/P2**: cooldown aislado por variante. Se comparte transporte y el
   test de manager exige una sola petición cuando sub recibe 429/Retry-After.
2. **LANG-02/P2**: posible sobrescritura de captions para igual URI. Se rechazan
   catálogos diferentes antes de asignar el motor; regresión de preflight.
3. **LANG-03/P2**: catálogo tras Stop→Play y menú de fuente anterior. Se sincroniza
   explícitamente y se usan revisiones de ID; prueba con libmpv real cubre
   reapertura y cambio de medio, rechazando identificadores antiguos.

La segunda revisión independiente no encontró bloqueos nuevos en el alcance.
Las pruebas de fixtures no acreditan disponibilidad remota. La prueba GUI sí
comprueba selección, vídeo, texto nativo, posición observada y persistencia.
Se corrigieron defectos del harness: ruta de base con `..`, selección ambigua de
English/English 2, lectura del texto antes de confirmar seek y una aserción de
progreso creciente incompatible con buscar hacia atrás. Los intentos fallidos
no cuentan como aprobados; ahora se compara el progreso con el checkpoint al cerrar.

Antes de GUI: suite 353 aprobadas/9 omitidas; después de las correcciones,
focalizadas 46 aprobadas/2 omitidas. La suite final secuencial aprobó **357**
pruebas y omitió **7**, incluyendo las opt-in nativas HTTP Referer/Origin/UA,
HLS local y reanudación local. Log: `.ai-local/languages/full-final.log`.
Las últimas correcciones del harness pasaron con la prueba GUI española final.
El análisis final terminó sin incidencias y la compilación Linux debug normal
`-t lib/main.dart` aprobó. Logs: `analyze-final.log` y `build-final.log` de
`.ai-local/languages/`. El bundle final es la aplicación normal, no el test GUI.
Entorno: Flutter 3.50.0-0.4.pre/Dart 3.14 beta del proyecto, Fedora Linux,
OpenH264 Cisco opcional por proceso. Sin cambios globales, commits ni pushes.

## Fuentes primarias y límites

Consultadas el 2026-11-17:

- [MegaPlay de Anilili Desktop, MIT-0](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/providers/megaplay/src/lib.rs): variantes sub/dub y tracks del episodio. No garantiza idiomas/disponibilidad de cada título.
- [AnimeAV1 de Anilili](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeAv1Provider.kt): SUB japonés/ES incrustado y DUB latino; catálogo 403 actual.
- [KickAssAnime de Anilili](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/KickAssAnimeProvider.kt): referencia de japonés/inglés, sin audio ES declarado.
- [Registro Zangetsu revisado](https://github.com/Spyou/zangetsu-providers/blob/87325be3757d7287674115ec2ca99c4478024fa6/index.json): fuentes en/zh, no contrato de audio ES.

El ZIP AnikenTV expresamente adjunto se leyó sin explorar archivos vecinos.
No contiene LICENSE/COPYING y las menciones españolas son de subtítulos;
ReAnime pide audio inglés. No se copió su código. AnimeOnsen ofrece subtítulos
es-ES/es-LA, no doblaje, y su ruta exige sesión/API; no se utilizó.
Miruro y otros hosts denegados no se volvieron a sondear en la matriz GUI:
`KONGROO_ENABLE_MIRURO=0`. No se reintrodujeron extractores experimentales.
**LANG-04/P1 · Criterio pendiente, externo:** audio español no verificado por
la denegación del catálogo AnimeAV1 y falta de alternativa declarada en las
referencias examinadas. Impide dar por terminada la solicitud de audio y
subtítulos en los tres idiomas. Reevaluar solo con una interfaz autorizada
accesible o evidencia nueva del servicio; no dar esta integración por funcional.
Otros hosts, títulos y Android/Windows permanecen pendientes.
