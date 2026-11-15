# Proveedores de metadatos

## Contrato implementado

`app/lib/domain/catalog/metadata_provider.dart` define `MetadataProvider`, `MetadataCapability`, `MetadataProviderConfiguration` y `MetadataProviderRegistry`. Cada adapter expone búsquedas, detalle, episodios y health como resultados tipados; la operación no soportada devuelve `ProviderUnsupported`, y “cero resultados” se distingue de un fallo.

`ProviderResult<T>` diferencia éxito, sin resultados, operación no soportada y fallo con clase y `retryAfter`. Solo red, timeout, cuota y disponibilidad temporal son reintentables por el helper actual. Credenciales faltantes, autenticación y respuestas inválidas requieren acción distinta. No se propagan excepciones, respuestas JSON ni mensajes sensibles a UI.

`ProviderAnimeMetadata` y `ProviderEpisodeMetadata` son modelos normalizados. La procedencia incluye `ExternalAnimeId` y timestamp UTC. Número de episodio y temporada siguen namespaced al proveedor; no se convierten en clave universal. Imágenes no se modelan hasta comprobar derechos/retención.

El registro no habilita por defecto ningún adapter, ordena solo los habilitados por capacidad y rechaza IDs/configuración duplicados o desconocidos. No hace llamadas ni prueba salud automáticamente. La composición de la demo conecta directamente `FakeMetadataProvider` como fuente local sintética; no se registra en el registry de providers externos.

## Estado de fuentes

| Fuente | Evidencia técnica | Uso en producto |
| --- | --- | --- |
| `FakeMetadataProvider` | Tres records totalmente sintéticos, IDs deterministas `demo`, búsqueda y detalle sin I/O | Conectado solo a la demo local para desarrollo/pruebas; no es catálogo real ni fuente descargada. No persiste la metadata |
| AniList | `data/anilist/AniListClient` legado funciona contra loopback; búsqueda pública no requiere token según documentación; límite debe adaptarse a headers y outages | Desactivado/desconectado hasta confirmar elegibilidad para app con biblioteca/seguimiento. Sin nuevas requests ni expansión de cache |
| TMDB | API oficial; requiere API key y aceptación de términos; atribución/logo/aviso obligatorio y regla distinto para uso comercial | Sin credenciales, decisión comercial ni atribución; no implementado |
| Kitsu Anime | Repo oficial de docs y especificación legacy JSON:API disponibles; la página actual `dev.kitsu.cloud` es Kitsu producción CGWire | Términos/cuota/retención para API Anime no confirmados; no implementado |
| Jikan | Prohibido por el alcance de esta misión | No se usa como respaldo |
| `media-index` | Referencia pública de layout index/detail/episodes/mappings y warnings de asociaciones erróneas entre temporadas | Solo lectura de README como referencia; no dependencia, code, CDN ni dataset |

### AniList

La documentación oficial dice que no se requiere auth para datos públicos; no hay scopes, el token expira en un año, refresh no existe e Implicit Grant lleva token en fragmento. La guía vigente muestra degradación temporal a 30 solicitudes/minuto frente a nominal 90. Términos prohíben backup/storage, acaparamiento y servicios competidores no complementarios de listas/tracking. No se puede determinar documentalmente la elegibilidad de AnimeApp, por lo que el adapter sigue fuera del composition root.

Fuentes: [Terms](https://docs.anilist.co/guide/terms-of-use), [Auth](https://docs.anilist.co/guide/auth/), [Implicit](https://docs.anilist.co/guide/auth/implicit), [Rate limiting](https://docs.anilist.co/guide/rate-limiting).

### TMDB

El FAQ oficial dice que uso no comercial gratuito necesita atribución, logo oficial y aviso de no afiliación en About/Credits. Antes de cualquier implementación debe registrarse una key, aceptar términos y aclarar si Kongroo/AnimeApp es comercial. Fuentes: [FAQ](https://developer.themoviedb.org/docs/faq), [Getting started](https://developer.themoviedb.org/docs/getting-started), [rate limiting](https://developer.themoviedb.org/docs/rate-limiting).

### Kitsu Anime

El README oficial de [`hummingbird-me/api-docs`](https://github.com/hummingbird-me/api-docs) describe la API de plataforma anime y remite a [Apiary legacy](https://kitsu.docs.apiary.io/). La documentación técnica pública no sustituye las condiciones de uso del dataset. No se inventan política de caché, cuota ni autorización.

## Añadir una fuente

1. Localizar términos oficiales y fecha/versionado de la documentación.
2. Registrar elegibilidad, cuota, atribución, licencia, autenticación y retención antes de implementar.
3. Crear adapter bajo `app/lib/data/<provider>/`, sin llevar DTOs o dependencias de red al dominio.
4. Exponer solo capacidades soportadas; denegadas/no implementadas van como resultado explícito.
5. Probar parser y errores con fakes manuales/loopback, fixtures mínimos, rate limit/retry/cancelación y provider caído.
6. No activar provider en registro de producto hasta pasar revisión, y no guardar datos hasta tener retención aprobada.

No almacenar catálogo completo, scrapear, prefetch global ni publicar datos de fuente en CDN.
