# OC-03 · Limpieza de proveedores y herramientas

La limpieza de la composición duplicada está verificada en Fedora. La
comparación de un episodio real con Anilili sigue abierta.

## Inventario y cambios

| Área | Referencias comprobadas | Decisión |
| --- | --- | --- |
| AnimeAV1 y TioAnime | Registro opt-in en `playback_providers_module.dart`, adaptadores `PublicEpisodeProvider`, fixtures en `public_playback_providers_test.dart`. | Conservar. Sus contratos de descubrimiento son distintos y ya comparten transporte e identificación. |
| MP4Upload y YourUpload | `public_embed_host_profiles.dart` configura ambos perfiles y `public_embed_host_resolver.dart` los ejecuta. Los tests de proveedores y transporte ejercitan las declaraciones y la validación del medio. | Conservar un resolver compartido con un perfil por host. `verifyMedia` distingue verificación HTTP de inspección de declaraciones en los tests. |
| AnimesDigital | Registro opt-in, suite del adaptador y dos herramientas diagnósticas. | Eliminar dos comprobaciones de esquema redundantes con el control de origen y un desempate que nunca se alcanzaba porque la colección ya tiene una clave por número de episodio. |
| Herramientas de AnimesDigital | `app/tool/README.md`, `animesdigital_live_harness_test.dart` y evidencia de diagnóstico S0-S. | Conservar ambas entradas y usar `PlaybackProvidersModule` en las dos. La CLI conserva su cliente independiente para inspeccionar manifiestos y segmentos. |
| Resolución directa y fuentes manuales | Registro de producción, pruebas del módulo y del proveedor `user_sources`. | Conservar. Resuelven candidatos directos y fuentes añadidas por el usuario. |
| Reproductor y metadatos | Composición de la app, coordinador, media_kit/libmpv, AniList, Kitsu, progreso y reanudación. | Fuera de las ediciones de limpieza. |

La auditoría de inventario fue independiente y de solo lectura. Se revisó
la propiedad del transporte tras el cambio: las herramientas cierran el
módulo de proveedores, y el cliente del manifiesto en la CLI se sigue
cerrando por separado. Se conservan las referencias históricas en el
[archivo de proveedores](../archive/providers/S0-2026-11-16/README.md).
No se identificaron resolutores activos duplicados ni dependencias de
paquetes sin uso demostradas por esta revisión.

## Hallazgos

- **LC-01 · P3 · Corregido.** Las dos herramientas creaban su propio manager,
  registro y resolver directo. Esto permitía que el diagnóstico divergiera de
  producción al cambiar la composición. Ambas usan ya el registro común.
- **LC-02 · P3 · Corregido.** `animesdigital_live_harness.dart` evaluaba
  `arguments.single` antes de comprobar cuántos argumentos recibió. Pasar
  `1 2` podía lanzar una excepción; ahora imprime el uso y sale con código 64.
- **LC-03 · P3 · Corregido.** Las dos guardas de esquema en
  `animesdigital_playback_provider.dart` repetían una comprobación incluida en
  la función de mismo origen. Se conserva la política existente de origen,
  puerto, credenciales y fragmento. Las pruebas del adaptador siguen pasando.
- **LC-04 · P1 · Abierto.** Falta observar un mismo episodio y servidor en
  Anilili y Kongroo. El [checkpoint de transporte](../missions/OC03-2-ANIME-TRANSPORT-2026-11-17.md)
  documenta un HEAD 403 de MP4Upload y un HEAD/GET parcial 500 de YourUpload
  en otra ejecución. Esos resultados no atribuyen la diferencia al cliente.

## Referencias de implementación

El ZIP de AnikenTV contiene un cliente Android. En
`data/MiruroRepository.kt`, `resolveSources` parte de AniList y busca el
número exacto en el proveedor, con orden preferido y hasta cinco intentos.
`ui/watch/WatchViewModel.kt` consume el resultado. `ui/watch/PlayerSurface.kt`
construye el `MediaItem`, configura el contexto de la petición y entrega la
posición de inicio a Media3. Se consultó como referencia local. El archivo
no trae un fichero de licencia identificado y no se incorporó su código.

La referencia de Anilili para Fedora se revisó en la revisión
`e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`. Su contrato de proveedor recibe
AniList y número de episodio y devuelve alternativas con URL, tipo y
cabeceras. Kongroo ya tiene un contrato equivalente entre candidato,
resolutor y motor. Para comparar una ruta hay que identificar qué provider
entregó la alternativa seleccionada en ejecución.
[Contrato de Anilili Desktop](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/wit/provider.wit).

En Fedora, `catalog.rs` consulta Miruro y los proveedores WebAssembly en
paralelo. Los nombres visibles del selector no siempre coinciden con el
ID del proveedor. Por ejemplo, `bee` corresponde a AniKoto, `hop` a
KickAssAnime y `moo` a AnimeGG en esta revisión del cliente.
`watch.rs` selecciona servidor por ID o por preferencias.
Envía la URL a libmpv directamente, salvo si aplica una transformación
específica o su detección de DNS activa el proxy para HLS o MP4.
`player.rs` limpia las cabeceras anteriores y entrega cabeceras de la
fuente y posición inicial a `loadfile`. Kongroo entrega las cabeceras
mediante `Media(httpHeaders: ...)` y verifica el seek en su propio motor.
Ninguna prueba vincula el uso del proxy o la selección de servidor
con los códigos HTTP observados en los dos CDN. La revisión de escritorio
publica su código bajo MIT No Attribution.
[Etiquetas de servidores](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src/lib/providers.ts),
[selección y transporte](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/watch.rs),
[entrega a libmpv](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/src-tauri/src/player.rs)
y [licencia](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/LICENSE).

Se consultaron el [repositorio de proveedores de Zangetsu](https://github.com/Spyou/zangetsu-providers)
y su [aplicación](https://github.com/Spyou/Zangetsu) el 17 de noviembre.
Los proveedores se registran por manifiesto. Esta limpieza no incorpora
su runtime ni copia extractores.

## Validación

- Fedora, Flutter 3.47.9 del proyecto. Antes y después, con
  `KONGROO_TEST_HTTP_REFERER=1 KONGROO_TEST_LOCAL_HLS=1 flutter test`,
  348 aprobadas y 10 omitidas. Evidencia en
  `.ai-local/cleanup-baseline.log` y `.ai-local/cleanup-after.log`.
- `flutter analyze` sin hallazgos, `git diff --check` limpio y CLI con
  argumentos extra comprobada con código de salida 64.
- No se modificaron los manifiestos de paquetes. La corrida de limpieza
  no ejercitó nuevos hosts por red ni mostró un episodio en ventana.
