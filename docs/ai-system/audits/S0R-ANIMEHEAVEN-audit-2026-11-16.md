# Auditoría S0-R — AnimeHeaven y su transporte MP4

**Fecha:** 2026-11-16
**Estado:** provider integrado; playback externo no verificado; S0 continúa abierta
**Recomendación:** no cerrar S0. Los tres mirrors publicados para el episodio
probado ya se intentaron por separado con el mismo player y ninguno presentó
un frame. Continuar solo con una fuente pública elegible nueva o con evidencia
de que la disponibilidad de un host cambió.

## Resumen ejecutivo

Se integró un provider AnimeHeaven y un resolver MP4 en el
`PlaybackProvidersModule` existente. La búsqueda pública de One Piece, episodio
1, llegó a `ProviderPlaybackRoute` y al único motor media_kit/libmpv. El sitio
publicó `mirror-cx`, `mirror-ct` y `mirror-ck`; se intentaron en procesos
secuenciales separados. En los tres casos apareció el error genérico de
apertura/decodificación y no hubo imagen. No hay log nativo conservado para
atribuir la causa. El resultado es **1 provider implementado, 0 reproducibles y
0/70 títulos**.

La revisión independiente no encontró P0/P1 de implementación en el alcance.
Encontró dos defectos P2 y luego un riesgo P2 en la primera corrección de
cancelación; los tres quedaron corregidos y comprobados en el árbol actual.
Persisten criterios de aceptación pendientes: no se vio un frame, el recorrido
completo desde la ficha AniList no se validó y no hay perfil de rendimiento del
provider ni del stream. Los nombres restantes de la allowlist no aparecieron en
la respuesta del episodio; no se fabricaron URLs para probarlos.

## Alcance y entorno

- Revisados: `app/lib/data/player/providers/animeheaven/`,
  `playback_providers_module.dart`, contratos del manager y provider, pruebas
  de parser/transporte/composición, `app/tool/animeheaven_live_harness.dart`,
  READMEs de módulos, documentación de arquitectura y estado S0-R.
- Versiones: Flutter `3.50.0-0.4.pre`, Dart `3.14.0-315.3.beta`, Dio `5.11.1`
  (lockfile).
- Entorno de la corrida anterior: Fedora 44, KDE Wayland, 7.5 GiB. No es el
  Fedora objetivo de 4 GB.
- Git: `main`, HEAD `b1bd952ac03c8711ce50cf22d249fa448d2e2880`; árbol ya sucio
  antes de esta misión. No se preparó índice, commit ni push.

## Fuentes técnicas

- Referencia upstream de la adaptación, commit `d7b80f1`, licencia MIT-0:
  [AnimeHeavenProvider.kt en Anilili](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/AnimeHeavenProvider.kt).
  La implementación en Kongroo es independiente; no se copiaron bloques de
  código.
- El archivo `app/pubspec.lock` fija Dio `5.11.1`; no se añadió dependencia.
- La referencia y clasificación de idiomas se registran en
  [`S0R-REFERENCE-REVIEW-2026-11-16.md`](../missions/S0R-REFERENCE-REVIEW-2026-11-16.md).

## Arquitectura y comportamiento revisados

- `AnimeHeavenPlaybackProvider` hace búsqueda por alias exacto, limita consultas,
  inspecciona episodios y solicita mirrors desde el endpoint público del sitio.
- `AnimeHeavenMp4Resolver` está separado del catálogo, permite hosts exactos y
  verifica estado HTTP, MIME `video/mp4` y el marcador `ftyp`. El probe pide un
  rango corto, retiene como máximo 12 bytes y no sigue redirects.
- La key pública asociada a la fila del episodio se envía solo a `gate.php`; no
  se comparte con el host multimedia. No se usan cuenta, cookie de usuario,
  autenticación, CAPTCHA, ejecución JS, descifrado ni impersonación.
- La URI efímera se conserva en memoria y llega al manager/ruta existentes. No
  se añadió player ni se imprime o persiste la URL.
- La fuente se etiqueta `Subtitulado (idioma no validado)`: el upstream declara
  contenido subtitulado, pero el idioma del episodio live no se confirmó. Solo
  se implementó MP4 progresivo; no se afirma HLS ni doblaje.
- El harness tiene un ID opcional de mirror estricto: si no está en las
  alternativas validadas, informa el error y no selecciona otro.

## Hallazgos y resolución

### AUD-S0R-01 — P2 — Clasificación incorrecta de error TLS

- **Evidencia inicial:** `DioExceptionType.badCertificate` se traducía a
  `unauthorized`, aunque no representa un rechazo HTTP 401/403.
- **Consecuencia:** el estado podía ocultar un problema de transporte y evitar
  que se contabilizara conforme al circuito de fallos transitorios.
- **Corrección:** se traduce ahora a `network`.
- **Regresión:** test de certificado TLS inválido espera
  `PlaybackProviderFailureKind.network`.
- **Estado:** RESUELTO; prueba actual pasa.

### AUD-S0R-02 — P2 — Cancelación durante stream no cubierta

- **Evidencia inicial:** el test existente solo cancelaba antes de iniciar la
  solicitud.
- **Corrección/prueba:** se añadió cancelación mientras el body permanece
  abierto; la prueba comprueba que `StreamController.onCancel` se complete. Otra
  prueba consume 512 chunks pequeños. `_moveNextOrCancel` añade un listener al
  token por avance y lo desregistra al resolverse `moveNext`; al cancelar, el
  token limpia sus listeners antes de invocarlos y el `finally` cierra el
  iterador.
- **Auditoría independiente:** confirmó el desregistro en éxito/error, el
  cierre en cancelación y los manejadores del future de `moveNext`. Limitación:
  no hay test específico de error emitido por el stream ni medición de memoria
  de una descarga grande.
- **Estado:** RESUELTO con cobertura focalizada; el perfil real de RAM sigue
  pendiente como criterio de rendimiento.

### AUD-S0R-03 — P2 — Selección silenciosa de otro mirror en harness

- **Evidencia inicial:** una variable de entorno con un ID no disponible podía
  caer silenciosamente al primer mirror.
- **Corrección:** un ID solicitado que no existe informa los candidatos y
  detiene la apertura; no cambia de servidor a escondidas.
- **Estado:** RESUELTO por inspección, análisis estático y selección por ID del
  harness. No se necesitó interacción dentro del player para probar los otros
  mirrors.

### AUD-S0R-04 — P2 — Listener acumulado en corrección intermedia

- **Evidencia:** una corrección intermedia usó un `Future.any` por chunk;
  listeners perdedores podían permanecer asociados al Future de cancelación.
- **Corrección:** se sustituyó por `_moveNextOrCancel`, con desregistro después
  de cada avance/error. La prueba de 512 chunks y la de cancelación activa pasan.
- **Revisión independiente:** confirmó que los listeners se eliminan en éxito y
  error, y que la cancelación limpia los listeners del token; no encontró un
  future colgante ni un error no atendido. No midió cardinalidad interna ni RSS.
- **Estado:** RESUELTO en el código actual; queda pendiente la medición real de
  recursos durante una fuente multimedia que sí reproduzca.

## Evidencia live y límites

- Capturas locales: `.ai-local/review/s0r-animeheaven-visible.png` y
  `.ai-local/review/s0r-animeheaven-mirror-switch.png` muestran `mirror-ct`;
  `.ai-local/review/s0-animeheaven-mirror-cx.png` y
  `.ai-local/review/s0-animeheaven-mirror-ck.png` muestran las otras dos
  alternativas. En las tres capturas de mirror se ve el error genérico y no hay
  frame. Son evidencia de fallo, no reproducción.
- No se conservaron logs nativos crudos que identifiquen si la falla fue HTTP,
  contenedor, codec u otra causa. No hay frame, audio, seek ni reproducción
  confirmada.
- El propietario respondió «Autorizar manualmente en KDE». Una captura posterior
  (`.ai-local/review/s0-kde-manual-auth-check.png`) ya no mostró el diálogo; el
  conector Wayland siguió devolviendo `Transport closed`. No se simuló entrada:
  se seleccionó cada mirror con la variable documentada del harness, una
  instancia por proceso, y se cerró antes de lanzar la siguiente.
- El recorrido usó un harness de desarrollador basado en la ruta y player de
  producción. No probó la navegación completa desde una búsqueda/ficha AniList.
- Se agotaron las tres alternativas ofrecidas por el episodio actual
  (`cx`, `ct`, `ck`). No hubo medición de RAM/CPU, arranque, reposo, playback o
  fugas de AnimeHeaven; la línea base previa es de 7.5 GiB.
- Riesgo residual de transporte: libmpv abre más tarde la URI validada y puede
  resolver DNS por separado. El resolver de esta integración no fija direcciones
  IP para esa segunda conexión. También se bloquean redirects en el probe HTTP,
  pero no se probó el comportamiento de redirects de libmpv. No se observó un
  abuso; son límites pendientes de investigación y no evidencia de explotación.

## Pruebas ejecutadas

Con el SDK aislado dentro del proyecto:

```text
flutter test --no-pub test/data/player/providers/animeheaven \
  test/data/player/providers/playback_providers_module_test.dart
Resultado: 13/13 pass.

flutter test --no-pub test/data/player/providers/animeheaven \
  test/data/player/providers/playback_providers_module_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/domain/playback_provider_contract_test.dart \
  test/player/provider_playback_route_test.dart \
  test/player/spike_player_module_test.dart
Resultado: 48/48 pass.

flutter analyze --no-pub
Resultado: sin issues en el paquete.

dart analyze lib/data/player/providers/animeheaven \
  lib/data/player/providers/playback_providers_module.dart \
  test/data/player/providers/animeheaven \
  test/data/player/providers/playback_providers_module_test.dart \
  tool/animeheaven_live_harness.dart
Resultado: sin issues.

python3 tools/ai/memory.py check
Resultado tras actualizar memoria/índices: [] (sin errores).

git diff --check
Resultado: sin salida. La comprobación adicional de whitespace en archivos
nuevos de provider, pruebas, harness y esta auditoría también pasó.
```

No se ejecutaron la CI completa, build Linux, test de Fedora 4 GB, prueba de
ficha AniList extremo a extremo ni medición de rendimiento del provider. Las
tres alternativas de este episodio sí se abrieron después de las correcciones
con libmpv; fallaron sin frame, como se detalla en la evidencia live.

El diagnóstico A/B del Gate 0 tampoco se ejecutó: `mpv --version` no está
disponible (`mpv` no aparece en PATH). No se instaló un binario en el sistema.
Así, el error de apertura/decode no puede atribuirse a la fuente/codec frente a
una diferencia de la integración libmpv.

## Reevaluación requerida

1. No repetir `cx`, `ct` o `ck` para One Piece ep. 1 mientras no haya evidencia
   de cambio en la respuesta o disponibilidad del host. Los nombres `ax` y `cy`
   están permitidos por el parser, pero no se ofrecieron en esta respuesta; no
   construir URLs por conjetura.
2. Para cualquier nueva fuente, ver un frame en la ventana, confirmar
   dimensiones y avance de posición, y revisar un log nativo sanitizado. Una
   URI o un `open` HTTP 200 no es criterio suficiente.
3. Validar el recorrido real desde ficha AniList y fallback del selector.
4. Medir recursos/arranque/uso durante reproducción en el Fedora objetivo de
   4 GB y revisar posible crecimiento de RSS.
5. Actualizar STATUS/HANDOFF y esta auditoría con evidencia posterior. No cerrar
   S0 automáticamente.

## Actualización de reevaluación — 2026-11-16

Tras la autorización del propietario para continuar después de la aprobación
manual en KDE, se probaron `mirror-cx` y `mirror-ck` con el harness y libmpv;
`mirror-ct` ya tenía evidencia visual. Los tres intentos terminaron en el mismo
error genérico sin frame. La captura de autorización ya no muestra el diálogo,
pero Wayland MCP continúa desconectado (`Transport closed`). No se generó ni
conservó log nativo crudo, y no se puede atribuir la causa. Dentro de las rutas
live ya probadas no hay otra fuente elegible que haya entregado media estática.
Esto no agota el inventario: la auditoría de Anivexa registra 28 candidatos y
solo tres probes live (AniChan, AniPM y Zoko); el resto no fue revisado
completamente. El siguiente paso es una inspección estática acotada de un
candidato no probado y, solo si ofrece un host distinto y una ruta ordinaria
pública, como máximo un GET sin sesión ni técnicas de evasión. Los demás
resultados previamente probados conservaron sus bloqueos 403/419 o dependencias
de sesión, challenge o transformación; no se repitieron. S0 permanece abierta.
