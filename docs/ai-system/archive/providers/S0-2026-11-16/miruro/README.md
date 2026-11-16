> ARCHIVO HISTÓRICO — Esta página se conserva como registro de un intento anterior; no describe el runtime actual. Los adaptadores y resolutores de este intento fueron retirados en S0-S (2026-11-16). Consulta el [índice vigente](../README.md) y la [línea base/estado S0-S](../../../../missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

# Proveedor Miruro — historial S0-A

> **Retirado del runtime el 2026-11-15.** Los archivos Dart de implementación
> ya no existen ni están registrados. Las pruebas fuente se conservan como
> `.dart.txt` no ejecutable en
> [`docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/`](../../../../../../docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/).
> Este README es documentación histórica, no un contrato de implementación
> activa. El GET público devolvió 403 y no se confirmó reproducción. Ver la
> [auditoría de limpieza posterior](../../../../../../docs/ai-system/audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

> Todo el contenido técnico restante describe el intento S0-A retirado; no hay
> archivos de implementación Miruro activos en el repositorio.

## Estado

En el intento S0-A, el adapter y su resolver se implementaron y registraron en
el manager existente. **No hubo reproducción externa confirmada.** El endpoint
público de configuración respondió HTTP 403 el 2026-11-15; el flujo no llegó a
obtener episodios ni fuentes accesibles en el entorno actual. La implementación
se retiró en la limpieza posterior.

Este módulo no crea un reproductor. Usa el `PlaybackProviderManager`, el
`PlaybackSourceSwitchService` y el único motor media_kit/libmpv ya existentes.

## Responsabilidades y archivos

| Archivo | Responsabilidad |
| --- | --- |
| `miruro_catalog_api.dart` | Contrato de API, transporte Dio acotado y mapeo de HTTP/timeout/cancelación |
| `miruro_catalog.dart` | DTOs del borde, decodificación JSON/XOR+gzip, episodios y alternativas |
| `miruro_playback_provider.dart` | Mapeo AniList → ID Miruro → episodio → fuentes del dominio y resolver directo MP4/HLS |
| `README.md` | Alcance, seguridad, dependencias, ejecución y límites |

El módulo se registra desde `../playback_providers_module.dart`. `Dio` 5.11.1
está fijado en `app/pubspec.lock`; el módulo posee un cliente HTTP y lo cierra
una vez al llamar `close()`.

## Flujo y contrato

1. Acepta `PlaybackEpisode.externalAnimeId` solo cuando su proveedor es `anilist`
   y su valor es un entero positivo. No infiere identificadores por título.
2. Consulta el mapeo AniList, busca el episodio regular solicitado y consulta
   configuración/alternativas de reproducción. Se omiten especiales.
3. Lee las claves, etiquetas, orden, visibilidad y relación padre/embed de la
   configuración pública; no mantiene una lista rígida de servidores.
4. Distingue `sub` (hard-sub), `ssub` (soft-sub) y `dub`. Agrupa cada pista y
   calidad como una fuente; cada backend/servidor es una alternativa dentro de
   esa fuente. Varias URLs de una misma alternativa con igual calidad no se
   cuentan como servidores distintos.
5. Reconoce URLs de embeds, pero no las envía a libmpv ni ejecuta JavaScript.
   Devuelve `unsupported` cuando solo existe una página embed.
6. Solo entrega medios directos HTTPS MP4/HLS al resolver. No crea una URL,
   sigue redirects, ni intenta transformar segmentos.

El dominio actual no transporta metadatos de subtítulos ni ventanas OP/ED. Por
eso el parser reconoce los datos de catálogo pero esta integración aún no
conecta subtítulos externos o skip-times al reproductor. DASH tampoco está
habilitado. Estos puntos no se consideran paridad completa.

## Red, cabeceras y recursos

- Una sola raíz: `https://www.miruro.to/api`. No se cambia de mirror tras 403 y
  no se siguen redirecciones.
- GETs HTTPS ordinarios con `Accept`; no se envían cookies, Authorization,
  Origin, headers arbitrarios, perfil de navegador ni credenciales.
- Timeouts de conexión/envío/recepción acotados a 8/8/12 s; una respuesta
  codificada se limita a 1 MiB y su expansión gzip a 4 MiB.
- No se reintentan 4xx, 5xx, redirects ni errores de transporte. HTTP 401/403 se
  convierte en `unauthorized`; 429, timeout y 5xx tienen errores tipados.
- El resolver acepta URLs HTTPS MP4/HLS y comprueba que el DNS actual entregue
  solo direcciones globalmente enrutables. Su lista IPv6 conservadora se
  contrastó con el [registro de direcciones especiales de
  IANA](https://www.iana.org/assignments/iana-ipv6-special-registry). Libmpv
  vuelve a resolver el host, por lo que queda un riesgo DNS TOCTOU documentado.
  No se realiza una petición de prueba HLS/MP4 ni se declara accesible un
  recurso por su URL.
- Las URLs del catálogo no se escriben en logs. Las cabeceras reenviadas se
  limitan al `Referer` público validado por el contrato existente; `Origin`,
  cookies y autenticación se descartan.

## Pruebas históricas

Las fuentes de las pruebas deterministas y del smoke opt-in se archivan como
`.dart.txt` no ejecutable en
[`docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/`](../../../../../../docs/ai-system/archive/S0-A-miruro-tests-2026-11-15/).
No hay comandos de prueba activos para este módulo. El smoke ordinario del
2026-11-15 obtuvo `status=403 kind=unauthorized`; no probó catálogo, episodios,
fuente, HLS o libmpv. Los fixtures sintéticos tampoco sustituyen reproducción
real.

## Referencia y procedencia

Se adaptó el formato observado en los tests y modelos de Anilili, no el runtime
Android. Referencias fijadas:

- [`MiruroCatalogApi.kt`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/MiruroCatalogApi.kt)
- [`MiruroCatalog.kt`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/remote/MiruroCatalog.kt)
- [`ProviderCatalog.kt`](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/app/src/main/java/com/anilili/data/ProviderCatalog.kt)
- [LICENSE](https://github.com/sanilili/Anilili/blob/d7b80f1f5b6c3d014317af471a8565749947397d/LICENSE), MIT No Attribution (MIT-0)

No se copiaron `withLegacyTrustAnchors`, los clientes Android, WebView,
cookies, pipe bridge, `clearance` ni resolutores de captcha. El trabajo Dart se
inspiró en los contratos/datos públicos descritos arriba y conserva esta
procedencia para continuidad.
