# Dependencias de la reproducción de MegaPlay

## cryptography 2.9.0

Biblioteca Dart bajo Apache-2.0, añadida para decodificar AES-256-CBC/PKCS7 del
JSON de fuentes que publica MegaPlay. El protocolo y los parámetros públicos
proceden de Anilili Desktop bajo MIT-0 y del script del propio servicio. Se
validan tamaño, bloques y JSON antes de admitir un candidato HTTPS.

Se reutilizan las dependencias ya resueltas del proyecto. No necesita otro
motor multimedia, un proceso OpenSSL ni una biblioteca nativa por plataforma.
Flutter recoge el archivo LICENSE del paquete en los avisos de la compilación.
[Paquete y licencia](https://pub.dev/packages/cryptography/versions/2.9.0).

## OpenH264 opcional en Linux x86_64

El Fedora probado tiene `noopenh264-2.6.0-4.fc44`: proporciona la ABI de
OpenH264 pero no un decodificador H.264. El player podía avanzar con audio y
sin salida de video. El códec oficial de Cisco permitió decodificar el mismo
medio con el mismo libmpv a 1920×1080.

`tools/player/run_kongroo_linux.sh --download-codec` descarga el binario
separadamente desde Cisco a `.ai-local/native-codecs/openh264-2.6.0/` y sale.
El código del proyecto no incorpora ese binario en el paquete de la app.
La descompresión se limita a 2 MiB y se verifica SHA-256 del ELF esperado.
La biblioteca descargada tiene el hash
`2f0cde7c6a6abcf5cae76942894ea42897fa677bce4ed6c91a24dd1b041d5f04`.

El usuario controla su uso por ejecución:

```bash
tools/player/run_kongroo_linux.sh --debug --openh264
tools/player/run_kongroo_linux.sh --debug --system-codec
```

Al seleccionar el códec local, el lanzador muestra
**OpenH264 Video Codec provided by Cisco Systems, Inc.**
y la ubicación del texto completo de licencia. La primera opción configura
la búsqueda de bibliotecas para ese proceso. La segunda usa el entorno de
bibliotecas existente del usuario. El lanzador no cambia paquetes, permisos,
configuración global o servicios de Fedora.

Las condiciones del binario Cisco y la licencia BSD se conservan completas
en [OPENH264-BINARY-LICENSE.txt](OPENH264-BINARY-LICENSE.txt).
[Release oficial](https://github.com/cisco/openh264/releases/tag/v2.6.0),
[licencia del binario](https://www.openh264.org/BINARY_LICENSE.txt).

## integration_test del SDK Flutter

Dependencia de desarrollo del SDK fijado, utilizada para recorrer la interfaz
real desde `main()` en Linux. Sus paquetes auxiliares quedan en el lockfile.
El test de red es opt-in y necesita una base de datos aislada dentro del
proyecto. No se incluye en las pruebas unitarias ordinarias ni convierte
fixtures en evidencia de reproducción remota.
[Documentación del SDK](https://docs.flutter.dev/testing/integration-tests).

## Corrección Linux de media_kit_video 2.0.1

La compilación conserva el paquete bajo MIT y genera una traducción de
`video_output.cc` con retención de `VideoOutput` durante el idle de software.
El archivo generado conserva el aviso original. Se compila en lugar de la
traducción original, con el resto del plugin y el mismo engine media_kit/libmpv.
El CMake del proyecto valida el patrón que modifica y vuelve a configurarse
si cambia la fuente upstream. El ajuste se limita a Linux.
[Contrato GTK del callback](https://docs.gtk.org/gdk3/func.threads_add_idle_full.html).
