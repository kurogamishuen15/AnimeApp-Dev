# Auditoría de limpieza de providers y resolutores S0

> **Snapshot histórico:** esta auditoría registra la primera limpieza, antes
> del port S0-A de Miruro. Miruro se añadió después y fue retirado en un
> seguimiento; el estado actual está en
> [S0-provider-cleanup-followup-audit](S0-provider-cleanup-followup-audit-2026-11-15.md).

**Fecha:** 2026-11-15<br>
**Alcance:** retirar únicamente adaptadores de anime y resolución de video
anteriores que no acreditaron reproducción externa. No se implementaron
proveedores nuevos.

## Resultado

La composición de datos de reproducción quedó sin integraciones externas: no
registra `AnimeProvider` ni `VideoHostResolver` concretos, no crea un cliente
HTTP y no hace solicitudes al abrirse. Se conservaron los contratos, el manager,
el source switch y el único motor media_kit/libmpv. La suite Flutter completa,
el análisis Flutter y Dart pasaron después de la limpieza.

La limpieza deja el proyecto preparado para recibir el siguiente diseño de
servidores, pero no habilita reproducción externa. S0 sigue incompleta, la
evidencia anterior continúa en 0/70 títulos y ningún proveedor queda declarado
funcional.

## Contexto y límites de Git

- Raíz verificada: `/home/kyouma/Vídeos/PROYECTO ANIME`.
- Rama: `main`.
- HEAD al comenzar: `b1bd952ac03c8711ce50cf22d249fa448d2e2880`.
- El checkout ya tenía cambios locales de Bloque A/S0, un ZIP de revisión,
  documentación y carpetas no rastreadas. Se conservaron; no se preparó el
  índice, no se hizo commit ni push y no cambió HEAD.
- Toolchain usada: Flutter `3.50.0-0.4.pre`, revisión
  `368ac9e40b`, Dart `3.14.0-315.3.beta`, en
  `.ai-local/toolchains/flutter`.

## Archivos retirados

Se comprobó el grafo de registro y las referencias Dart antes de retirar estos
archivos:

1. `app/lib/data/player/providers/animeav1/animeav1_playback_provider.dart` —
   adaptador de catálogo/episodios cuya resolución pública terminaba en
   `unauthorized`; no llegó una URI reproducible a libmpv.
2. `app/lib/data/player/providers/tioanime/tioanime_playback_provider.dart` —
   adaptador de catálogo/episodios que descubría cinco alternativas, ninguna
   de las cuales produjo reproducción externa.
3. `app/lib/data/player/providers/animegg/animegg_playback_provider.dart` —
   adaptador experimental de AnimeGG; las variantes llegaron a una URI, pero
   libmpv no reportó dimensiones de video y no se confirmó un cuadro.
4. `app/lib/data/player/providers/public_site_http.dart` — transporte HTTP
   propio de los prototipos retirados; no tenía consumidores fuera de ellos.
5. `app/lib/data/player/providers/video_hosts/public_media_video_host_resolver.dart`
   — resolver estático compartido; sus resultados de prueba no equivalían a
   reproducción y persistía la diferencia entre validación DNS en Dart y la
   resolución posterior del proceso nativo.
6. `app/test/data/player/providers/public_playback_provider_test.dart` —
   fixtures/tests específicos de los adaptadores y del transporte eliminados.
   No son pruebas ejecutables del runtime restante.

La eliminación de esos archivos del árbol de trabajo no reescribe Git. El
test fuente que estaba rastreado sigue disponible en el historial/base Git; las
salidas sanitizadas y los resultados previos permanecen en
`.ai-local/review/s0-real-playback-2026-11-15/` y los informes históricos.

## Archivos y contratos conservados

- `app/lib/domain/player/providers/`: modelos y contratos neutrales,
  incluidos `PlaybackSourceProvider` y `PlaybackVideoHostResolver`.
- `app/lib/application/player/providers/playback_provider_manager.dart` y el
  circuit breaker: registro, selección, cancelación, fallback y diagnósticos.
- `app/lib/application/player/source_switching/`: transición de la fuente
  hacia el reproductor existente.
- `app/lib/data/player/providers/mock/`: implementación para pruebas.
- `app/lib/data/player/providers/playback_providers_module.dart`: punto de
  composición preservado, ahora con un manager vacío y sin recursos HTTP.
- `app/lib/data/player/engine/`, `app/lib/application/player/` y
  `app/lib/app/player/`: el engine media_kit/libmpv, coordinador, rutas,
  lifecycle y UI existentes no fueron retirados ni reemplazados.
- Se conservaron los README históricos de AnimeAV1, TioAnime, AnimeGG y
  `video_hosts`, el informe S0, las auditorías anteriores, el estado/handoff y
  los logs sanitizados. Los README indican que las implementaciones descritas
  fueron retiradas.

La nueva prueba
`app/test/data/player/providers/playback_providers_module_test.dart` comprueba
que el composition root abre con cero providers registrados. Una búsqueda
posterior en `*.dart` no encontró referencias a las clases/transportes
retirados; las menciones restantes están marcadas como historia en documentos.

## Segunda pasada de auditoría

Se revisó de nuevo el árbol de referencias, el composition root, los contratos
genéricos y las pruebas de manager/player. No se encontró una importación o
instanciación activa de los adapters eliminados. La auditoría fue una segunda
pasada local del coordinador, no una revisión independiente por otro agente.
No se observó una regresión causada por la limpieza en la suite completa.

## Verificaciones ejecutadas

Desde `app/`, con el SDK aislado anterior:

| Comando | Resultado |
|---|---|
| `flutter analyze --no-pub` | exit 0; sin issues |
| `dart analyze lib test` | exit 0; sin issues |
| `flutter test --no-pub` | exit 0; 267 pasaron, 6 optativas omitidas |
| `dart format --output=none --set-exit-if-changed lib/data/player/providers/playback_providers_module.dart test/data/player/providers/playback_providers_module_test.dart` | exit 0; formato correcto |
| Enlaces Markdown locales en 17 documentos actualizados | exit 0; sin destinos locales faltantes |
| `python3 tools/ai/memory.py check` | exit 0; sin errores |
| `git diff --check` y `git diff --cached --check` | exit 0; sin errores de whitespace |

La suite completa prueba el estado actual del árbol, pero no es una prueba live
de servidores ni de playback externo. Los seis tests omitidos son optativos;
la evidencia S0 anterior deja constancia de que los smokes externos no
confirmaron video.

## Hallazgos y riesgos pendientes

- **P1 del objetivo general, sigue abierto:** no existe un proveedor ni
  resolutor externo registrado y no se confirmó video externo. Esto es una
  limitación conocida del trabajo previo, no una regresión de esta limpieza.
- **P2:** al retirar tests específicos de hosts, sus parsers ya no tienen
  fixtures ejecutables. La evidencia anterior es histórica; la próxima
  implementación debe aportar tests nuevos del contrato y del host elegido.
- No se verificó una reproducción live en esta ejecución, ni se hicieron
  requests nuevos a catálogos/hosts.
- Los README de AnimeAV1/TioAnime conservan detalles históricos; no deben
  interpretarse como interfaces instaladas. El README de AnimeGG se aclaró
  adicionalmente para distinguir su estado histórico `RESOLVING`.

## Decisión de preparación

El runtime y su composición están limpios de las implementaciones obsoletas
identificadas. Los contratos reutilizables, el player existente y el motor
permanecen intactos. El proyecto está preparado para que el siguiente prompt
defina la nueva integración; no está preparado para afirmar playback, cerrar S0
ni avanzar por sí solo a otra fase.
