# Resolutores de medios directos

## Responsabilidad

El módulo contiene normalizadores compartidos de candidatos que ya encontró
un proveedor de episodios. No busca animes, no visita embeds, no extrae medios,
no hace solicitudes de red y no crea ni controla un reproductor. El único motor
sigue siendo `media_kit/libmpv`.

| Archivo | Responsabilidad |
|---|---|
| `direct_media_host_resolver.dart` | Comprueba sintácticamente HTTPS público, formato directo (MP4/HLS/DASH/WebM), expiración y convierte el candidato a `PlayableSource`. |

## Contratos y dependencias

Implementa `PlaybackVideoHostResolver` desde Domain. Recibe un `PlaybackSource`
y un `SourceCandidate`; entrega `PlayableSource`, `unsupported`, `expired` o
`cancelled`. Las cabeceras admitidas se limitan al Referer público validado y al
User-Agent explícito de medios. No transporta cookies, Authorization ni
cabeceras arbitrarias. El resultado conserva formato declarado cuando la URL
no lleva una extensión reconocible y distingue disponibilidad listada,
respuesta de transporte y reproducción comprobada.

El resolver usa Dart y el SDK de Flutter, sin Dio, WebView ni APIs nativas de
Linux. Rechaza destinos IP literales no globales y nombres locales obvios, pero
no resuelve DNS ni valida redirecciones: como no realiza transporte, no elimina
DNS rebinding/TOCTOU. Un HLS, MP4 o DASH aceptado por el parser no certifica que
sea accesible, válido o decodificable.

## Pruebas

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/hosts/direct_media_host_resolver_test.dart
```

Estas pruebas validan normalización y rechazo de candidatos; no acceden a
hosts reales ni prueban `libmpv`. Los tests de Miruro usan transporte fake.
La evidencia del intento live y sus respuestas 403 figura en la [auditoría de
migración](../../../../../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md).

No quedan perfiles ni resolutores activos para MP4Upload, YourUpload, Zilla,
StreamSB, Netu, OK.ru, Mega u otros embeds experimentales. Para añadir un
protocolo de host nuevo, crea su módulo y README independiente, valida el flujo
con pruebas offline y registra el resolver una sola vez en
`PlaybackProvidersModule`; no lo dupliques dentro de un proveedor de anime.
