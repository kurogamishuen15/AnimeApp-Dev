# Adaptadores de fuentes de reproducción

## Estado S0-S (2026-11-16)

El composition root registra un provider candidato, AnimesDigital, junto al
único normalizador reutilizable `DirectMediaHostResolver`. La implementación de
AnimeHeaven se retiró
porque los tres mirrors probados llegaron a libmpv sin presentar un cuadro, y
su flujo específico de gate no dejó un resolver reutilizable. Los intentos
AnimeAV1, TioAnime, AnimeGG, Miruro y AnimeOnline Ninja tampoco tienen código
Dart activo. Sus guías históricas están en
[`archive/providers/S0-2026-11-16`](../../../../../docs/ai-system/archive/providers/S0-2026-11-16/README.md);
la evidencia de playback permanece en las auditorías S0 enlazadas allí.

AnimesDigital busca títulos exactos, descubre episodios paginados y soporta un
iframe público que expone un manifiesto HLS directo. No ejecuta JavaScript ni
usa su alternativa Blogspot. El medio se normaliza por `direct-media` y llega
al player existente. Hasta verificar video visible en Kongroo, su estado es
`candidate`, no `verified_video`.

## Responsabilidades y límites

| Componente | Responsabilidad | Estado |
|---|---|---|
| `domain/player/providers` | Modelos y contratos neutrales; sin Flutter, Dio, `dart:io` ni libmpv | Activo; evolución S0-S en curso |
| `application/player/providers/PlaybackProviderManager` | Registro estático, orden, cancelación, deduplicación, breakers y resolución/fallback | Activo y compartido; no posee un engine |
| `application/player/source_switching` | Cambio/fallback entre fuentes a través del coordinator actual | Activo y reutilizable |
| `PlaybackProvidersModule` | Composition root de adapters/resolvers del producto | AnimesDigital `1.0.0` (TTL de fuente cero); un normalizador `direct-media` |
| `media_kit/libmpv` | Abrir y controlar el medio normalizado | Se mantiene en `data/player/engine` y no se consulta el catálogo |

La arquitectura S0-S separa identidad, match de anime, episodio de proveedor,
candidato de fuente, resolver del host y medio listo para libmpv. El manager y
los contratos actuales son la base: no se crea otro registro, coordinador de
reproducción ni player. La primera migración de un adapter debe entregar
metadatos de host, modalidad (`media`, `embed` o `redirect`), idioma conocido o
`unknown`, expiración y procedencia. Un embed no se pasa a libmpv como si fuera
un archivo.

## Añadir un adapter de forma estática

1. Implementar la búsqueda/matching y el listado de episodios en el módulo de
proveedor, sin importar Flutter ni el engine.
2. Devolver candidatos tipados y no asumir que un HTTP 200 es media reproducible.
3. Mantener el protocolo de cada host en un `VideoHostResolver` independiente;
un adapter de anime no debe repetir resolutores compartidos.
4. Registrar ambos una sola vez desde `PlaybackProvidersModule`, con ID estable,
versión, prioridad y capacidades explícitas.
5. Añadir pruebas offline para matching, episodios, candidate, cancelación,
redacción, redirects, formato y fallback. Añadir un smoke online acotado y
opt-in si existe una ruta pública ordinaria.
6. Integrar el resultado a la ruta y al engine existentes. Verificar frame,
avance, cierre y retorno a la ficha antes de usar el estado `verified_video`.

No se soportan scripts remotos, código arbitrario de extensiones, DRM,
autenticación, CAPTCHA, WAF ni transformación de streams protegidos. No se
registran URLs firmadas completas en logs o documentación.

El módulo AnimesDigital tiene su contrato, límites, dependencias, pruebas y
estado en [`animesdigital/README.md`](animesdigital/README.md). Un proveedor
nuevo debe tener su propio README y no debe copiar la resolución de host.

## Dependencias, pruebas y referencias

No se añadieron dependencias: AnimesDigital usa Dio, ya existente. Cada
adaptador de datos usa una implementación HTTP portable; el dominio y la
coordinación no dependen de Linux, Android o Windows. El adapter posee su Dio
por defecto y lo libera desde el composition root al cerrar la aplicación.

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/flutter test --no-pub \
  test/data/player/providers/animesdigital \
  test/data/player/providers/playback_providers_module_test.dart \
  test/application/playback_provider_manager_test.dart \
  test/domain/playback_provider_contract_test.dart
```

Canario live de resolución del proveedor y manifiesto, desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/dart run tool/animesdigital_live_harness.dart
```

El normalizador genérico preserva fuentes directas HTTPS MP4/HLS/DASH y rechaza
esquemas no HTTPS, credenciales, fragmentos, puertos distintos de 443 y
destinos locales/IP privados conocidos. No resuelve DNS ni valida redirects;
no debe confundirse con un extractor de hosts. Un smoke opt-in entregó el HLS
público de prueba a libmpv y avanzó 2 s, pero no mostró una ventana ni un
episodio de anime. La suite del player está separada en
[`TESTING.md`](../../../../../TESTING.md).
Los patrones y licencias upstream estudiados para S0-S se resumen en
[`S0-S baseline`](../../../../../docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).
