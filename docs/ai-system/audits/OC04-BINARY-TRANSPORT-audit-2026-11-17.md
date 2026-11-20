# OC-04 · Corrección del transporte binario de Miruro

Se corrigió un fallo interno reproducido en la cadena HTTP, catálogo,
provider, manager y resolver. La reproducción real de Tokyo Ghoul:re 9
sigue bloqueada antes de obtener la fuente.

## Evidencia y cambios

**BT-01 · P1 · Corregido.** En
`app/lib/data/player/providers/public_playback_http.dart`, `_request`
decodificaba cada respuesta exitosa como UTF-8 estricto. Eso incluía las
llamadas a `readBytes`. Un catálogo XOR+gzip válido fallaba como
`invalidResponse` antes de llegar a `MiruroCatalogApi.decodePayload`.
El test del manager se modificó para entregar título, configuración y
respuesta de episodio en el formato binario upstream. Falló con el código
previo y pasó después de separar la decodificación textual de la lectura
binaria. Se conserva la decodificación permisiva del prefijo de errores HTTP,
la validación estricta de `read`, los límites y la cancelación del transporte.

**BT-02 · P2 · Corregido.** `MiruroCatalogApi` omitía el Referer del catálogo
que incluye la referencia upstream. Ahora `readBytes` acepta las cabeceras
tipadas existentes y el adaptador genera `https://<origen>/` en cada petición.
Las pruebas comprueban el cambio de origen durante el failover y que las
cabeceras de una lectura binaria no se filtren a otra petición. El UA de
Kongroo permanece como identidad de estas solicitudes. La comparación de red
no atribuye el bloqueo externo a este defecto.

La implementación se cotejó con `crates/core/src/miruro.rs` y `net.rs` de
Anilili Desktop en `e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd`, consultados el
17 de noviembre de 2026. El primero entrega bytes al decoder y envía el
Referer correspondiente a cada origen. El segundo usa un perfil de navegador
en su transporte. Se consultó la separación de responsabilidades y no se
añadieron dependencias ni mecanismos de emulación.
[Miruro upstream](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/miruro.rs),
[cliente HTTP upstream](https://github.com/sanilili/desktoprepo1/blob/e1c84dbbe9ddcd78a68d3431a9f97f8603eeafcd/crates/core/src/net.rs).

## Pruebas ejecutadas

- Fedora. Se usó el SDK Flutter 3.50.0-0.4.pre y Dart 3.14.0 del proyecto,
  coherente con las rutas de paquetes ya generadas en `app/.dart_tool`.
  El primer intento con el SDK 3.47.9 encontró incompatibilidad con esas
  rutas y falló al compilar el framework. Se repitió con el SDK correcto.
- Regresión antes de corregir, un test del manager con cuerpos binarios:
  0 aprobadas y 1 fallida. `binary-before.log` registra que el manager
  devolvía `PlaybackProviderFailed` en lugar del stream esperado.
- Toda la carpeta `test/data/player/providers`: **32 aprobadas**.
  Incluye lectura binaria por loopback real, decoder, manager, cabeceras,
  límites, cancelación, 403 y reintento 5xx con fixtures. No prueba vídeo.
- `flutter analyze --no-pub`: sin hallazgos.
- Un auditor independiente revisó primero el fallo y después el código
  corregido en modo de solo lectura. Confirmó BT-01 corregido y no detectó
  nuevas regresiones P0/P1. Su intento inicial de Flutter fue interrumpido
  para evitar concurrencia y no se cuenta como resultado de pruebas.

La evidencia local está en `.ai-local/bee-fix/`, excluida de Git.

## Comprobación real y límite pendiente

El GET de identificación de AniList 100240, con la identidad de Kongroo,
devolvió HTTP/2 403 con HTML de Cloudflare. Un segundo GET con el Referer
del catálogo y su Accept documentado también devolvió 403. El cuerpo
mostraba una página de bloqueo explícito y no un catálogo JSON o binario.
No se identificó la regla concreta del servidor. Esto no es un error de
decodificación ni demuestra que cambiar el UA resolviera el acceso.

Después de la corrección se ejecutó `PlaybackProvidersModule.open()` y
`manager.resolveCandidates` para el episodio 9 de AniList 100240, con la
composición real. El resultado fue:

```text
anilist=100240 episode=9 kind=forbidden stage=anime status=403 host=www.miruro.to mime=text/html
```

No se obtuvo una URL reproducible ni se abrió el episodio en el motor.
El defecto binario está corregido. El acceso al catálogo continúa denegado
por el servidor y falta evidencia de vídeo de este episodio en Kongroo.
La transformación síncrona XOR/gzip conserva el límite de expansión de
8 MiB y no permite cancelación durante su ejecución. No se recomienda
cerrar la misión de reproducción con este resultado.
