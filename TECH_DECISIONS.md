# Decisiones técnicas de AnimeApp

Registro compacto de decisiones aprobadas y propuestas pendientes. Las decisiones de esta página no sustituyen ADR detallados futuros.

| Tema | Estado | Decisión o propuesta | Consecuencia / evidencia pendiente |
| --- | --- | --- | --- |
| 1. Cliente/UI | Aprobado para F0.4 | Flutter + Dart. | Fedora/toolchain Linux verificados; analyzer conserva fallo LSP documentado. Ver [ADR-001](docs/adr/ADR-001-cliente-flutter-dart.md). |
| 2. Video | Aprobado como punto de partida | `media_kit`/libmpv detrás de `PlaybackEngine`; el registro local incluye wrapper `media_kit_video`. | Compatibilidad, recursos y rendimiento aún requieren F2.1–F2.2. Ver [ADR-002](docs/adr/ADR-002-motor-video.md). |
| 3. Estado | Propuesta | Riverpod. | No aprobado ni agregado. Ver [ADR-003](docs/adr/ADR-003-estado-riverpod.md). |
| 4. Navegación | Propuesta | go_router. | No aprobado ni agregado. Ver [ADR-004](docs/adr/ADR-004-navegacion-go-router.md). |
| 5. Persistencia | Propuesta | Drift sobre SQLite. | Spike y aprobación pendientes en F1.6. Ver [ADR-005](docs/adr/ADR-005-persistencia-drift.md). |
| 6. Red | Propuesta | Dio. | Spike y aprobación pendientes; mantener tras puerto. Ver [ADR-006](docs/adr/ADR-006-red-dio.md). |
| 7. Secretos | Plan lo especifica; aprobación formal no consta | flutter_secure_storage detrás de puerto de plataforma. | Verificar mecanismos/licencias por SO antes de F1.9. Ver [ADR-007](docs/adr/ADR-007-secretos-flutter-secure-storage.md) y [ADR adicional A09](docs/adr/additional/ADR-A09-almacen-seguro.md). |
| 8. Catálogo | Plan lo especifica; aprobación formal no consta | AniList GraphQL, cliente propio, sin codegen. | Verificar API/consultas y errores en F1.8; ver [ADR-008](docs/adr/ADR-008-anilist-graphql.md). |
| 9. Sync backend | Principio local-first aprobado; proveedor concreto pendiente | Supabase (Postgres + Auth + RLS) según plan maestro. | Aprobación, modelo, RLS, privacidad/costos y pruebas pendientes antes de F5. Ver [ADR-009](docs/adr/ADR-009-backend-supabase.md); contrato FakeRemote en [A11](docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md). |
| 10. QR | Plan lo especifica; aprobación formal no consta | qr_flutter genera; mobile_scanner escanea solo Android. | Permisos y ciclo de vida deben probarse en F5. Ver [ADR-010](docs/adr/ADR-010-qr.md). |
| 11. Temas | Principio de packs aprobado; mecanismo pendiente | Motor propio con ThemeExtension. | Validación, fallback y no ejecutar código de packs en F3. Ver [ADR-011](docs/adr/ADR-011-temas.md). |
| 12. Subtítulos | Plan lo especifica; aprobación formal no consta | Estilo mediante propiedades de mpv. | Confirmar propiedades expuestas/efecto en F2.6. Ver [ADR-012](docs/adr/ADR-012-subtitulos-mpv.md). |
| 13. Tests | Herramienta usada en F0; estrategia especificada en plan | flutter_test + fakes manuales. | Validar fakes/contratos del núcleo en F1.12. Ver [ADR-013](docs/adr/ADR-013-pruebas.md). |
| 14. Empaquetado Linux | Plan lo especifica; aprobación formal no consta | Flatpak, formato principal. | Manifest, permisos, codecs/licencias y flujo de actualización pendientes de F5.1. Ver [ADR-014](docs/adr/ADR-014-empaquetado-flatpak.md). |
| Arquitectura por capas | Principios aprobados | Dependencias hacia contratos de dominio; dominio Dart puro; composición de adaptadores. | Descomposición modular se define en F1.3. Ver [ADR adicional A01](docs/adr/additional/ADR-A01-arquitectura-por-capas.md). |
| Errores, logs, ajustes y progreso | Requisitos/principios; detalles propuestos | Mantener tipos de resultado, redacción, preferencias y progreso separados de infraestructura. | Ver ADR adicionales [A04](docs/adr/additional/ADR-A04-errores-y-resultados.md), [A05](docs/adr/additional/ADR-A05-logs-y-redaccion.md), [A06](docs/adr/additional/ADR-A06-ajustes.md), [A10](docs/adr/additional/ADR-A10-progreso-local.md). |
| OAuth AniList | Requisito de cuenta; flujo no especificado/aprobado | Flujo y scopes mínimos pendientes de documentación primaria en F1.9. | No introducir secreto de cliente. Ver [ADR adicional A08](docs/adr/additional/ADR-A08-oauth-anilist.md). |
| Proveedores | Principio aprobado | Adaptadores aislados; mock primero; fuentes reales desactivadas hasta evaluación técnica/legal. | Contratos se verifican en F2. |
| Repositorios | Aprobado | `AnimeApp-Dev` privado; `AnimeApp` público, vacío hasta versión aprobada; historial público independiente. | Publicación futura por selección explícita de archivos y aprobación manual. |
| Commits | Aprobado | Conventional Commits; rama de desarrollo `main`; commit final por subfase cuando sea práctico. | Identidad privada configurada solo en Git local. |
| D3 — Licencia del proyecto | Pendiente | No se ha seleccionado licencia ni creado un archivo LICENSE. | No bloquea F0.3; resolver antes de distribuir código o binarios y revisar licencias de dependencias. |
| Temas | Principio aprobado | Packs opcionales, validados y sin código ejecutable; Lite independiente. | Implementación posterior en F3. |

## Licencia del proyecto

La licencia aún no está decidida. No se publica ni se crea un `LICENSE` provisional que pueda confundirse con una licencia válida. D3 es una decisión pendiente del propietario y no bloquea F0.3; debe resolverse antes de distribuir.

## Reglas para modificar decisiones

Una propuesta no se convierte en decisión por aparecer en el plan. Para una decisión arquitectónica nueva registrar problema, alternativas, consecuencias y pruebas requeridas; no modificar decisiones confirmadas sin autorización.
