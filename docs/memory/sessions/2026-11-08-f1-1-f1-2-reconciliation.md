# Conciliación F1.1/F1.2 con el plan maestro

Fuente: solicitud y transcripción de las 14 decisiones originales proporcionada por el propietario el 2026-11-08; documentos del proyecto dentro de la raíz autorizada.
Fecha: 2026-11-08
Módulo: núcleo, requisitos y decisiones tecnológicas
Estado: conciliación documental terminada; F1.1 pendiente de aprobación formal; F1.2 pendiente de aprobación de propuestas antes de implementación.
Decisión: ADR-001..014 corresponden uno-a-uno a los 14 elementos transcritos; ADR-A01..A13 preservan análisis adicionales.
Evidencia: `PROJECT_PLAN.md`, `TECH_DECISIONS.md`, `docs/requirements/F1.1-CORE-REQUIREMENTS.md`, `docs/adr/README.md`, `PROGRESS.md`, verificación de links, `memory.py check`.

## Conciliación de F1.2

La pasada anterior había numerado como decisiones originales una lista derivada. Se reordenó ADR-001..014 para coincidir exactamente con la transcripción del propietario: Flutter/Dart, media_kit, Riverpod, go_router, Drift, Dio, flutter_secure_storage, AniList GraphQL propio sin codegen, Supabase, QR, ThemeExtension, estilo mpv, tests y Flatpak.

Coincidencias/diferencias corregidas:

- Riverpod, go_router, Drift y Dio coinciden con propuestas ya registradas; siguen sin aprobación formal.
- AniList estaba registrado genéricamente como cliente de lectura; GraphQL, cliente propio y ausencia de codegen se añadieron como especificación nueva del plan.
- La selección de Supabase concreta el backend antes pendiente. Se conserva el principio aprobado local-first/contrato REST; SDK/API y RLS requieren validación y decisión futura.
- El mecanismo ThemeExtension concreta el principio aprobado de packs, pero no se declaró formalmente aprobado.
- flutter_secure_storage, QR, subtítulos por propiedades mpv, estrategia de fakes y Flatpak constan en la lista del plan; el registro local no demostraba aprobación formal.
- Aprobaciones locales conservadas: Flutter/Dart para el cliente y media_kit/libmpv como punto de partida. No se alteró el principio de proveedores mock/aislados, ni que el backend no aloje video.

Los 13 análisis de la primera pasada se preservaron bajo `docs/adr/additional/` y se excluyen del conjunto de decisiones original.

## Auditoría de F1.1

La versión anterior tenía 12 FR + 12 NFR. Se conservaron los IDs, se agregaron FR-13..FR-18 para las seis capacidades del MVP omitidas explícitamente en `PROJECT_PLAN.md` (búsqueda, ficha, selección de episodio, clip mock, cambio de fuente conservando posición y reanudación). FR-12 y NFR-12 se conservaron como candidatos sin contar en el baseline porque no tienen fuente explícita en el plan. NFR-13 registra el límite explícito de no alojar video. El baseline resulta en 17 FR + 12 NFR activos (29); no se planteó como meta de cantidad.

Las tablas asignan prioridad/estado, fase, dependencia, fuente, método de verificación y criterio de aceptación por requisito. Seguridad, offline, rendimiento, modularidad, targets multiplataforma y alcance del MVP quedan trazados. El presupuesto numérico de rendimiento sigue pendiente de medición real en dispositivo objetivo de 4 GB.

Decisiones de requisitos a confirmar por el propietario: aprobación del baseline; si FR-06 (desvincular y borrar credenciales) y FR-11 (semántica temporal explícita) quedan como Must; los candidatos FR-12/NFR-12; presupuesto cuantitativo después de medir el hardware objetivo.

## Estado Git y trabajo previo

Al comienzo ya había cambios ajenos en `AGENTS.md`, `.codex/agents/` y `docs/ai-system/`. No se modificaron ni se mezclaron. Los documentos de proyecto que se concilian tenían los cambios documentales propios de F1.1/F1.2 de la tarea previa; se conservaron. Commit/push de esta conciliación queda registrado en la entrega final.

## Verificación

- Enlace/composición interno: 40 documentos revisados; todos los destinos existen dentro de la raíz, sin seguir symlinks.
- Consistencia automática: 17 FR y 12 NFR activos aparecen tanto en tablas como en matriz; 14 ADR originales y 13 adicionales detectados.
- `python3 tools/ai/memory.py index`: 34 documentos, 124 fragmentos. `memory.py check`: sin hallazgos.
- `git diff --check` y revisión de formato de 40 documentos Markdown: sin problemas ni espacios finales.
- No se cambió código de producto ni se agregaron dependencias. No se avanzó a F1.3.

## Git y publicación

El remoto local `origin` apunta a `kurogamishuen15/AnimeApp-Dev`; `git ls-remote` confirmó que `main` es accesible y la memoria F0.2 registra que este remoto fue creado privado. La consulta de metadatos del conector GitHub devolvió 404, así que no se usó para inferir privacidad. La rama local ya tenía el commit `11158f6` por delante de `origin/main`, correspondiente a cierre F0 previo. Se confirmarán solo rutas documentales de esta misión; no se hará push porque ello también enviaría ese commit previo ajeno al alcance de la conciliación.
