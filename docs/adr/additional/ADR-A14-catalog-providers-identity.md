# ADR-A14: catálogo desacoplado e identidad local

- Estado: **propuesta parcialmente implementada; pendiente de aceptación formal del propietario**.
- Fecha: 2026-11-09.
- Alcance: contratos de metadatos, identidad interna, crosswalk, membership local e integración demo offline.
- No reemplaza ADR-008 (AniList GraphQL), ADR-005 (Drift), ADR-A10 (progreso) ni ADR-A11 (sync remoto).

## Contexto

El contrato legado exponía el identificador entero de AniList y no ofrecía identidad local, crosswalk ni membership durable. La solicitud requiere que la app pueda mostrar datos sin cuenta y preservar biblioteca/progreso sin servicios externos. La arquitectura F1.3 se conserva: dominio Dart puro, Fedora/Linux primero, composición en `app/` y adaptadores añadidos por necesidad.

Las condiciones de AniList, TMDB y Kitsu Anime no se consideran resueltas para el uso de una app con biblioteca/seguimiento. Por eso los proveedores reales permanecen desconectados. El objeto `VerifiedExternalAnimeReference` puede construirse desde código Dart y **no autentica ni prueba** su evidencia; solo deben llegar al resolver datos procedentes de un adaptador confiable o una acción explícita del usuario.

## Decisión propuesta

1. Cada anime tiene un `AnimeId` local opaco UUID v4. `(providerId, externalId)` es un crosswalk y nunca la clave primaria de biblioteca o progreso.
2. Los puertos y modelos quedan en `domain/catalog`; proveedores implementan `MetadataProvider` fuera del dominio. El registry es default-disabled y no hace solicitudes al construirse.
3. Los enlaces se crean por ID exacto namespaced cuando los aporta un adaptador confiable, por referencia oficial previamente verificada o por confirmación explícita del usuario. Títulos parecidos no fusionan identidades. Un crosswalk existente no se reasigna.
4. La identidad, los enlaces y la membership viven en Drift. Los metadatos de proveedor no se guardan como catálogo persistente. Los documentos JSON heredados no se borran ni reinterpretan automáticamente.
5. El progreso continúa en el repositorio F1.10, separado de identidad, membership y proveedor. El flujo demo reutiliza ese repositorio y usa el `AnimeId` local como `ContentId`; no conecta un reproductor.
6. Para el recorrido de desarrollo, `FakeMetadataProvider` ofrece fixtures deterministas sintéticos sin red. Esta fixture no representa datos de AniList/TMDB/Kitsu ni habilita esos proveedores.
7. El estado de biblioteca `planned / watching / completed`, su default `planned` y su UI se incorporan **provisionalmente** para hacer comprobable el recorrido. Son decisiones de demostración reversibles y no políticas de producto aprobadas. El progreso no cambia el estado automáticamente.

## Persistencia y migración

El esquema actual es v6. La migración v5→v6 agrega `library_entries.status` con default `planned` y `CHECK` de los tres valores. Las rutas históricas se prueban desde v1, v2, v3, v4 y v5; se conserva settings, cache legado, documentos JSON, progreso tipado, identidades, crosswalks y membership. Las restricciones usan PK/FK/índices existentes; no se creó un segundo repositorio ni una segunda tabla de biblioteca o progreso.

## Consecuencias y límites

- Biblioteca y progreso pueden abrirse offline y sobreviven al cierre/reapertura de SQLite.
- La UI demo puede buscar, consultar detalles, añadir sin duplicar, cambiar estado y guardar progreso del episodio demostrativo `episode:1`.
- La metadata del fake se vuelve a consultar en memoria para presentar títulos después del reinicio; solo la identidad/crosswalk, membership y progreso son persistentes.
- `VerifiedExternalAnimeReference` sigue siendo una afirmación del caller: no pasar instancias creadas a partir de datos no confiables sin verificarlas en el adapter.
- No hay autenticación, sync de lista, proveedor real, cache de catálogo, retención externa, reproducción, selector real de episodios ni migración automática de JSON legado.
- El arranque normal de una app instalada usa su base propia de Application Support. Las pruebas de esta misión y la prueba del binario Linux usan exclusivamente una base aislada bajo `.ai-local/`; nunca se abrió la base personal del desarrollador.
- No se añadió código para Android, Android TV o Windows ni dependencias nuevas.

## Evidencia de implementación

- Contratos: `app/lib/domain/catalog/`.
- Orquestación sin Flutter/SQL/HTTP: `app/lib/application/catalog/catalog_service.dart`.
- Fixture offline: `app/lib/data/metadata/fake_metadata_provider.dart`.
- UI y composición: `app/lib/app/catalog/`.
- Persistencia: `app/lib/data/local_db/`, Drift schema v6.
- Pruebas SQLite en archivo: `app/test/data/local_db/app_database_test.dart` y `catalog_identity_repository_test.dart`.
- Recorrido widget offline con HTTP bloqueado, estado/progreso y reapertura: `app/test/widget_test.dart`.
- Informe actualizado: [`docs/architecture/catalog-testing.md`](../../development/catalog-testing.md) y [`docs/architecture/catalog-system-audit.md`](../../architecture/catalog-system-audit.md).

## Aprobación pendiente del propietario

1. Aceptar, ajustar o rechazar esta arquitectura complementaria.
2. Definir estados/defaults de biblioteca para producto; los tres valores actuales son provisionales.
3. Confirmar la elegibilidad y condiciones de uso/retención antes de conectar AniList, TMDB o Kitsu.
4. Decidir la futura relación entre contenido local y metadatos/progreso por episodio.

La implementación y sus pruebas **no constituyen aprobación formal** de ADR-A14 ni de las reglas provisionales de estado.
