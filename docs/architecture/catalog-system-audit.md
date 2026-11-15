# Auditoría del sistema de catálogo

Fecha: 2026-11-09
Alcance: auditoría inicial de código y documentación antes de diseñar el nuevo límite de proveedores.
Árbol auditado: `main` en `5a7f39a4fe1728118d41d0f8313c93ec9492dfb2`.

## Identidad y alcance del repositorio

La misión adjunta llama al producto “Kongroo”; el repositorio, el paquete Flutter y la identidad visible siguen siendo AnimeApp (`anime_app`). Esta implementación no cambia el nombre, el paquete, las fases existentes ni la arquitectura F1.3. La estructura conceptual `Core/Features/Integrations/Platform` del adjunto no existe hoy y reestructurar el scaffold para crearla sería un cambio mayor. El trabajo se adapta a `app/lib/domain`, `app/lib/data` y `app/lib/app`.

El worktree ya tenía modificaciones concurrentes en `AGENTS.md`, `.codex/agents/`, `docs/ai-system/` y memoria. Se conservaron; ninguna se usó como archivo de esta misión. La ejecución base se hizo antes de editar el módulo.

## Estado encontrado

| Área | Estado físico antes de esta misión | Límite observado |
| --- | --- | --- |
| Catálogo de dominio | `domain/catalog/anime_summary.dart` y `anime_catalog_repository.dart`; ID entero de AniList en el resumen y un puerto Dart puro de búsqueda | No había identidad interna ni contratos para varios proveedores |
| AniList | `data/anilist/anilist_client.dart`: Dio/GraphQL, búsqueda pública read-only, errores tipados y rate gate | No hace auth/mutations; no está conectado al inicio ni a UI |
| Caché | `OfflineFirstAnimeCatalog` y tabla `latest_anime_search`, un único resultado explícitamente solicitado | No tiene TTL aprobado ni política de retención revisada; no se amplió |
| Persistencia | Drift schema v4 al inicio de la misión | Progreso tipado F1.10 ya está implementado en `domain/progress` y `playback_progress_entries`; no se reescribió |
| Identidad/biblioteca | No había tablas `anime_identity`, crosswalk ni membership local | No se podía demostrar que progreso y lista local sobrevivieran sin proveedor |
| F1.9 | `SecureCredentialStore` y adaptador `flutter_secure_storage` | OAuth, callback AniList y runtime de Secret Service no implementados/verificados |
| UI/reproductor | Scaffold Linux y widget inicial; ningún reproductor ni flujo de catálogo | Los contratos nuevos no se conectan a UI ni reproductor |
| Proveedor auxiliar | No existe Kitsu/TMDB adapter; no se añadió Jikan ni `media-index` | Términos, credenciales/atribución y licencia de uso no autorizan integrar ahora |

F1.10 no es el modelo JSON opaco que aparece en algunos registros históricos previos. El commit presente contiene `ContentId`, `EpisodeId`, `PlaybackProgress`, checkpoints y Drift v4; el README de progreso y la prueba `playback_progress_repository_test.dart` muestran su contrato. Esta corrección de estado se documenta sin cambiar ese módulo.

## Inspección y evidencia base

Se leyeron `PROJECT_PLAN.md`, `TECH_DECISIONS.md`, `docs/memory/DECISIONS.md`, ADR-008/A07/A10, los READMEs de dominio, AniList y persistencia, esquema Drift y pruebas de DB/caché/progreso. La CI previa se ejecutó desde la raíz del proyecto con `PATH` seleccionando el SDK aislado documentado y `PUB_CACHE` dentro de `.ai-local/`:

```text
Flutter 3.50.0-0.4.pre
Dart 3.14.0-315.3.beta
bash scripts/ci.sh — exit 0
Flutter analyze — sin issues
Flutter tests — 49 pasaron
```

No se hizo una petición real a AniList/TMDB/Kitsu. No se midió rendimiento del catálogo, porque no hay flujo de producto conectado ni proveedor autorizado. La verificación funcional pertenece al loopback y a SQLite local.

## Investigación de fuentes primarias

### AniList

- Los [términos del API](https://docs.anilist.co/guide/terms-of-use) prohíben usarlo como respaldo/almacenamiento, recolectar datos en masa y usarlo dentro de servicios competidores no complementarios del tipo lista/seguimiento. AnimeApp contempla biblioteca y seguimiento; no hay interpretación/autorización específica que confirme elegibilidad. **Conclusión operativa, no dictamen legal:** mantener el cliente fuera del producto y no ampliar la caché hasta obtener esa confirmación.
- La [guía de autenticación](https://docs.anilist.co/guide/auth/) dice que el acceso a datos públicos no requiere login, que no hay scopes, que los access tokens duran un año y que no hay refresh tokens.
- La [guía de Implicit Grant](https://docs.anilist.co/guide/auth/implicit) devuelve el token en el fragmento de la URL y reserva el flujo a clientes que harán las solicitudes. Un servidor loopback HTTP no recibe ese fragmento automáticamente.
- La [guía de límites](https://docs.anilist.co/guide/rate-limiting) advierte que el límite está degradado temporalmente a 30 solicitudes/minuto aunque el valor nominal documentado sea 90; se deben atender cabeceras y `Retry-After`, sin asumir una cuota fija.

### TMDB

La [guía oficial](https://developer.themoviedb.org/docs/getting-started) requiere registrar una clave y aceptar términos. El [FAQ oficial](https://developer.themoviedb.org/docs/faq) exige atribución y logotipo, fija un aviso de no afiliación, limita el uso gratuito a propósitos no comerciales y remite usos comerciales a licencia. No hay clave ni decisión comercial/licencia/atribución incorporada; el proveedor queda inactivo.

### Kitsu Anime

El repositorio oficial [hummingbird-me/api-docs](https://github.com/hummingbird-me/api-docs) describe Kitsu como una plataforma anime y remite a la documentación legacy [Apiary](https://kitsu.docs.apiary.io/). Esa documentación técnica muestra JSON:API y endpoints públicos de lectura, pero no se pudo confirmar allí un texto vigente completo de términos, retención ni cuota para el uso concreto. La documentación actual con nombre Kitsu bajo `dev.kitsu.cloud` se refiere a la plataforma de producción de animación CGWire; no se confunde con Kitsu Anime. No se integra Kitsu hasta hallar autorización y límites vigentes.

### `media-index` (solo referencia)

El [README de sanilili/media-index](https://github.com/sanilili/media-index) separa índice, detalle, episodios e IDs cruzados y describe fallos de asociación entre temporadas; se usó solo para extraer esas preguntas de diseño. Su README describe una base estática agregada de AniList/TMDB y una reconstrucción periódica; no se consultó ni se importó código, dataset, CDN ni proceso de recopilación. La misión prohíbe usarlo como dependencia o respaldo.

## Hallazgos que conducen al cambio

1. `AnimeSummary.id` amarraba el contrato de búsqueda a un entero externo; título no es una clave segura, y un ID de AniList no puede ser la clave local.
2. No existía crosswalk namespaced ni una regla contra merges por coincidencia de título.
3. No existía tabla local de identidad ni membership de biblioteca, pese a progreso local separado.
4. Los errores del proveedor legacy no cubren un registro extensible de capacidades/estado ni el caso “no soportado” como resultado explícito.
5. Las fuentes actuales no autorizan activar proveedores públicos o sincronización OAuth con el alcance de lista/seguimiento.

Se implementó una base incremental de contratos puros, identidad/crosswalk y biblioteca local. Los límites y las tareas pendientes están en [`catalog-system.md`](catalog-system.md) y [`ADR-A14`](../adr/additional/ADR-A14-catalog-providers-identity.md).

## Integración local comprobada — 2026-11-09

La subfase siguiente conectó esta base a una UI mínima offline sin integrar providers externos ni reconstruir repositorios:

| Área | Resultado físico/comprobado |
| --- | --- |
| Presentación | `CatalogSearchPage`, ficha y biblioteca llaman a `CatalogService`; no importan Drift ni HTTP |
| Provider demo | `FakeMetadataProvider` tiene fixtures sintéticos deterministas, namespace `demo`, no hace I/O |
| Identidad/membership | Reutiliza `AnimeIdentityRepository`/`LocalLibraryRepository`; external key y membership tienen PK únicas; alta repetida conserva status |
| Progreso | Reutiliza `PlaybackProgressRepository`; no se añadió tabla/progreso paralelo |
| Migración | Schema v6; v1/v2/v3/v4/v5→v6 probado con snapshots/SQLite real; v5→v6 añade solo `status` por default y CHECK |
| Persistencia UI | Widget test bloquea `HttpClient`, añade/cambia estado/guarda 2700 s, cierra módulo y reabre el mismo archivo temporal |
| Arranque Fedora | Bundle Linux debug abrió DB v6 bajo `.ai-local/`, rasterizó primera trama, `integrity_check=ok`, biblioteca/progreso vacíos; no se tocó Application Support personal |

Resultados de ejecución en el mismo SDK Flutter beta aislado: 9 pruebas focalizadas y 62 Flutter pasaron, Dart/Flutter analyze y formato sin issues, checker positivo + diez negativos, build Linux debug y CI exit 0 (40 pruebas de IA y 62 Flutter). La sesión con comandos/códigos es [`catalog-local-integration`](../memory/sessions/2026-11-09-catalog-local-integration.md).

Auditoría independiente read-only no encontró duplicación de tabla/repositorio ni defecto de persistencia. Señaló que el arranque normal de la aplicación instalada usa su base app-owned de Application Support; por eso la verificación de esta misión usó `KONGROO_DATABASE_PATH` restringido a `.ai-local/`. La creación de `VerifiedExternalAnimeReference` no está protegida criptográficamente; esta confianza caller-owned queda documentada y no debe exponerse a datos no verificados.

ADR-A14 se actualizó al estado de propuesta parcialmente implementada, no aceptada. El estado/default de biblioteca es provisional; la búsqueda de la demo no acredita elegibilidad, términos, cuotas o retención de AniList/TMDB/Kitsu. No hay player, OAuth, sync de lista ni código anticipado para Android, TV o Windows.
