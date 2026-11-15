# Auditoría — implementación de proveedores reales

Fecha: 2026-11-14
Estado: trabajo implementado; resultado funcional pendiente
Recomendación: **no aceptar el flujo como operativo** hasta reproducir un episodio real en Fedora.

## Resumen

AnimeAV1 y TioAnime se implementaron como adaptadores de `PlaybackSourceProvider`,
se registraron en el `PlaybackProviderManager` existente y se conectaron desde la
ficha AniList al selector y al player `media_kit`/libmpv ya existente. El cambio
no crea un segundo player ni usa autenticación, cookies, JavaScript de terceros,
CAPTCHA o mecanismos de evasión.

El criterio principal de producto **no se cumplió**: ninguna fuente probada
reprodujo un episodio real. TioAnime entregó episodios y cinco servidores para el
episodio 1, pero ninguno avanzó la posición en libmpv. AnimeAV1 entregó su iframe,
que respondió 403. No se afirma que un proveedor funcione de extremo a extremo.

## Alcance y entorno

- Proyecto: `/home/kyouma/Vídeos/PROYECTO ANIME`; rama `main`.
- Flutter aislado del repositorio: 3.47.9; Dart 3.13.7; Fedora Linux con libmpv.
- Se conservó la configuración global de Flutter y no se instalaron dependencias.
- No se crearon commits ni se hizo push. El árbol ya tenía cambios concurrentes;
  estos se preservaron y no se preparó índice Git.
- Revisión independiente de `auditor_codigo`, secuencial, solo lectura.

## Implementación examinada

- `app/lib/data/player/providers/public_site_http.dart`: GET HTTPS ordinario,
  host de página permitido, redirect desactivado, respuesta acotada a 2 MiB,
  timeout compartido y cancelación Dio; denegaciones tipadas.
- `app/lib/data/player/providers/animeav1/` y `tioanime/`: búsqueda de título
  exacto, validación de número de episodio contra la lista pública y resolución
  únicamente de URI directa `.m3u8`/`.mp4` mostrada en HTML corriente.
- `playback_providers_module.dart`: Dio compartido y prioridades AnimeAV1 30,
  TioAnime 20. Ninja no está registrado.
- `app/lib/app/catalog/` y `provider_playback_route.dart`: AniList ID/títulos/
  episodio → manager → selector → player existente. La ficha cancela solicitudes
  pendientes al abandonar la ruta.
- `PlaybackEpisode` conserva ID externo y aliases para el lookup; los enlaces
  `streamingEpisodes` de AniList no se abren como media.
- `.README.md` de los módulos de catálogo, providers, dominio, coordinación y
  engine se actualizaron. El resumen de estado está en `PROGRESS.md`,
  `TESTING.md`, `PROJECT_STATE.md` y `AI_HANDOFF.md`.

## Evidencia de proveedores

| Proveedor | Búsqueda/episodios | Resolución y reproducción | Estado |
|---|---|---|---|
| TioAnime | GET público encontró coincidencia exacta para `Shingeki no Kyojin`; la ficha tenía episodios 1–25; el episodio 1 listó cinco servidores. | StreamSB expiró; YourUpload expuso un MP4, pero libmpv no lo abrió; Mega/OK.ru/Netu no dieron un stream directo reproducible. La prueba live exigió avance de posición y falló. | Adaptador integrado; no operativo. |
| AnimeAV1 | Catálogo SvelteKit público identificó el título; payload de detalle confirmó episodio 1 y página pública expuso iframe. | GET normal al iframe respondió 403; no se reintentó con headers alternativos. | Adaptador integrado; no operativo. |
| AnimeOnline Ninja | GET a `https://ww3.animeonline.ninja/` respondió 403 tras redirección. | Sin ruta confirmada; no hubo bypass. | No registrado. |
| JKAnime | GET `/buscar/naruto` respondió 200 en el primer muestreo; un muestreo posterior ordinario respondió 403. | La lista de episodios investigada usa POST AJAX con CSRF; no se llamó ni se portó porque la solicitud pública ya no fue estable y no se necesita resolver token para continuar. | No registrado; bloqueado por 403 observado. |
| AnimeJara | `/catalogo/` fue legible y mostró caja de búsqueda. | La apertura del detalle desde el catálogo expiró en navegador; un GET ordinario posterior falló con HTTP error (status no registrado). No se confirmaron episodios ni servidores. | No registrado; ruta no confirmada. |

Las peticiones no usaron sesión, headers de challenge, solver, CAPTCHA,
credenciales ni proxy. Los resultados describen solo las respuestas observadas en
esta sesión. La documentación por módulo enlaza fuentes de referencia Aniyomi
Apache-2.0 consultadas para reconocer rutas; no se copió código. No se atribuye a
esas licencias derecho sobre videos o streams.

Fuentes técnicas de referencia: [AnimeAV1 extension](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeav1/src/eu/kanade/tachiyomi/animeextension/es/animeav1/AnimeAv1.kt), [TioAnime extension](https://github.com/yuzono/anime-extensions/blob/master/src/es/tioanimeh/src/eu/kanade/tachiyomi/animeextension/es/tioanimeh/TioanimeH.kt), [AnimeOnline Ninja extension](https://github.com/yuzono/anime-extensions/blob/master/src/es/animeonlineninja/src/eu/kanade/tachiyomi/animeextension/es/animeonlineninja/AnimeOnlineNinja.kt), [catálogo público AnimeJara](https://animejara.com/catalogo/). El fallo LSP de `Content-Length` en paths UTF-8 se relaciona con el [issue oficial Flutter #191309 y fix #191377](https://github.com/flutter/flutter/issues/191309).

## Hallazgos

### P1 — El requisito de reproducción real sigue incumplido

- Estado: **abierto / criterio de aceptación pendiente**.
- Ubicación: `app/test/data/player/providers/public_playback_provider_test.dart:146`
  y aserción en línea 219; la extracción directa está en
  `app/lib/data/player/providers/tioanime/tioanime_playback_provider.dart:274`.
- Evidencia: la prueba hace búsqueda, obtiene servidores, los resuelve e intenta
  abrirlos con el engine/coordinator real. La aserción requiere que la posición
  avance; la corrida live no encontró un servidor que lo hiciera. AnimeAV1 fue
  denegado con 403 antes de entregar media.
- Reproducción: ejecutar el comando opt-in bajo “Verificación”.
- Consecuencia: la ficha puede identificar y cargar episodios, pero el propietario
  todavía no puede seleccionar un episodio reproducible con estos proveedores.
- Acción: probar un endpoint públicamente accesible compatible con libmpv; no
  degradar la prueba a “HTTP 200” ni tratar un iframe como stream.
- Regresión requerida: conservar el test live que exige avance de posición y
  registrar un episodio/servidor solo después de una corrida Fedora exitosa.

### P1 — Filtro incompleto de IPv4 mapeada a IPv6 (corregido)

- Estado: **corregido y cubierto**.
- Ubicación: `app/lib/data/player/providers/public_site_http.dart:185`.
- Evidencia: la primera revisión independiente advirtió que `::ffff:127.0.0.1`
  y `::ffff:10.0.0.1` pasaban el filtro de dirección IPv6. Ahora se detectan y
  clasifican con las reglas IPv4.
- Regresión: prueba negativa `public target check rejects IPv4-mapped private
  IPv6 addresses` en `app/test/data/player/providers/public_playback_provider_test.dart`.

### P2 — URL firmada renovada puede quedar fuera de la allowlist exacta

- Estado: riesgo no reproducido, limitación documentada.
- Ubicación: `app/lib/app/player/provider_playback_route.dart:36` y
  `app/lib/application/player/source_switching/README.md`.
- Evidencia: el player recibe URIs exactas resueltas al abrir la ruta. Si una
  futura resolución de servidor entrega otra URI firmada para el mismo host, la
  coordinación actual la rechazará.
- Consecuencia: un cambio de servidor posterior podría fallar tras caducidad de
  un enlace temporal.
- Acción sugerida: renovación delegada al provider y confiada solo después de
  comprobar esquema/destino y vinculación con el servidor seleccionado; mantener
  la allowlist exacta mientras eso no se implemente.
- Regresión requerida: fake que devuelva una segunda URI distinta tras expirar la
  primera; validar rechazo arbitrario y aceptación del resultado renovado.

### P2 — Interacción gráfica del flujo todavía no observada

- Estado: pendiente de comprobación visual.
- Ubicación: `app/lib/app/catalog/anime_detail_page.dart:234` y
  `app/lib/app/catalog/catalog_home_page.dart:159`.
- Evidencia: se compilaron la ruta principal y los tests existentes, pero no se
  operó una ventana gráfica de Kongroo para llegar de ficha a reproductor. La
  prueba live de proveedor sí ejerció `findSources` y el player libmpv directamente.
- Consecuencia: no hay evidencia de foco, layout o acciones de la ficha en la
  sesión gráfica actual.
- Acción: después de disponer de un stream playable, recorrer Home → ficha →
  episodio → servidor → video en Fedora y guardar evidencia.

## Verificación

Comandos relevantes ejecutados con Flutter 3.47.9 aislado:

- `flutter analyze --no-pub`: limpio.
- `flutter test --no-pub --reporter compact`: 250 aprobadas, 6 omitidas por
  gates opt-in.
- Tras el último cambio de filtro: analyze limpio y suite focalizada de provider,
  domain y manager: 25 aprobadas, 1 live omitida por defecto.
- `flutter build linux --release --no-pub`: exit 0 tras el cambio IPv4-mapped.
- `scripts/ci.sh`: 40 pruebas Python pasan; checker sintético confirma sus casos,
  formato, Dart analyze, Flutter analyze y las 250 pruebas pasan. El proceso
  termina exit 1 por el gate de imports en `app/lib/app/player/spike_player_page.dart`,
  que importa `dart:io` desde UI. No pertenece al cambio provider y se preserva
  para resolver por separado.
- Prueba live `KONGROO_LIVE_PROVIDER_SMOKE=1`: falló como criterio de playback,
  pues ningún servidor probado reprodujo. Esta falla es evidencia, no un test
  unitario verde.
- No se midieron CPU/RAM de reproducción real ni fugas de la sesión del player
  remoto, porque no llegó a haber playback. Los GET tienen límites de 2 MiB,
  timeout y cancelación; esto no sustituye las mediciones de rendimiento.
- F0 Flutter: el SDK local es 3.47.9 aislado y contiene el backport local
  documentado del conteo de bytes UTF-8 para Content-Length LSP. No se cambió el
  SDK global ni se deshabilitó el analyzer; la suite completa y `flutter analyze`
  pasaron con esa toolchain. No se modificaron reglas de CI.

## Verificación reproducible

Desde `app/`:

```bash
unset FLUTTER_ROOT
export PATH="../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
export PUB_CACHE="../.ai-local/pub-cache"
flutter analyze --no-pub
flutter test --no-pub test/data/player/providers/public_playback_provider_test.dart \
  test/domain/playback_provider_contract_test.dart \
  test/application/playback_provider_manager_test.dart
KONGROO_LIVE_PROVIDER_SMOKE=1 flutter test --no-pub \
  test/data/player/providers/public_playback_provider_test.dart \
  --plain-name 'live TioAnime search'
```

El comando live es un gate de comportamiento real y actualmente falla hasta que
un servidor abra y avance reproducción en libmpv.

## Cierre y criterio de reevaluación

El código de integración está presente y las verificaciones automatizadas locales
son reproducibles; **el resultado solicitado todavía no se alcanzó**. No aceptar
el flujo como funcional hasta que un episodio real reproduzca en libmpv en Fedora,
se revise la interacción gráfica y se vuelva a medir memoria/CPU bajo reproducción.
No se hizo commit, push ni publicación.
