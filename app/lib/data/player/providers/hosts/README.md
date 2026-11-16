# Resolutores de hosts multimedia

## Responsabilidad

Los resolutores normalizan candidatos multimedia que ya encontró un proveedor
de episodios. No buscan anime, no extraen fuentes de páginas de anime y no
crean ni controlan un reproductor. El único motor continúa siendo
`media_kit/libmpv`.

## Archivos

| Archivo | Función |
|---|---|
| `direct_media_host_resolver.dart` | Normaliza candidatos HTTPS `direct-media` cuya ruta termina en `.mp4`, `.m3u8` o `.mpd`; preserva expiración, procedencia y el único Referer HTTPS público permitido. |

El resolver directo **no hace una petición de red** ni certifica disponibilidad,
formato real, manifiesto válido o autorización. Un smoke opt-in enviado a
libmpv abrió el manifiesto de prueba HLS y avanzó la posición 2 s; el runtime
reportó pistas H.264, pero no dimensiones ni una ventana/frame visible. No es
un episodio de anime ni un host específico. La validación de redirects y
direcciones IP después de resolver DNS requiere un adaptador de red/host; el
normalizador solo rechaza destinos literales privados/locales conocidos y no
elimina DNS rebinding/TOCTOU. No sigue redirecciones ni implementa proxy.

## Contratos, errores y dependencias

Implementa `PlaybackVideoHostResolver` del dominio y recibe
`PlaybackSource` + `SourceCandidate`. Devuelve `PlayableSource`, `unsupported`,
`expired` o `cancelled`; usa solo SDK de Dart/`dart:io` para revisar IPs
literales y no depende de Flutter, Dio, WebView ni libmpv. El mismo código es
compilable en Linux, Android y Windows, aunque la compatibilidad de esos dos
últimos destinos no se ha validado con builds.

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/hosts/direct_media_host_resolver_test.dart
```

Smoke de HLS público, opt-in y limitado a `media_kit/libmpv`:

```bash
KONGROO_TEST_PUBLIC_HLS=1 ../.ai-local/toolchains/flutter/bin/flutter test \
  --no-pub --concurrency=1 test/player/public_hls_host_integration_test.dart
```

La prueba usa un provider sintético y una URL de muestra técnica; no integra ni
certifica ningún provider de episodios. En la máquina actual el smoke alcanzó
duración 634584 ms y posición 2038 ms con pistas declaradas H.264 y dimensiones
`null`; la visualización y el audio no se observaron.

Al incorporar un resolver de host nuevo, añádase aquí un README del módulo si
adquiere estructura propia, pruebas de contrato offline y registro versionado
desde `PlaybackProvidersModule`. Nunca duplique un host dentro de cada
`EpisodeSourceAdapter`.
