# Decisiones técnicas de AnimeApp

Registro de decisiones aprobadas y validaciones pendientes. El propietario aprobó las 14 selecciones del plan maestro el 2026-11-08 como arquitectura de referencia; esta aprobación no autoriza instalar todas las dependencias ni implementar fuera de fase. Ver [registro de ADR](docs/adr/README.md).

| Tema | Estado | Decisión o propuesta | Consecuencia / evidencia pendiente |
| --- | --- | --- | --- |
| 1. Cliente/UI | Aprobado para F0.4 | Flutter + Dart. | Fedora/toolchain Linux verificados; analyzer conserva fallo LSP documentado. Ver [ADR-001](docs/adr/ADR-001-cliente-flutter-dart.md). |
| 2. Video | Aprobado como punto de partida | `media_kit`/libmpv detrás de `PlaybackEngine`; el registro local incluye wrapper `media_kit_video`. | Compatibilidad, recursos y rendimiento aún requieren F2.1–F2.2. Ver [ADR-002](docs/adr/ADR-002-motor-video.md). |
| 3. Estado | Aprobado como selección arquitectónica (2026-11-08) | Riverpod. | Ciclo de vida, cancelación, fakes y licencia por validar antes de F1.3/F1.4. Ver [ADR-003](docs/adr/ADR-003-estado-riverpod.md). |
| 4. Navegación | Aprobado como selección arquitectónica (2026-11-08) | go_router. | Flujos de retorno, restauración, targets y licencia por validar en F3.3. Ver [ADR-004](docs/adr/ADR-004-navegacion-go-router.md). |
| 5. Persistencia | Aprobado como selección arquitectónica (2026-11-08) | Drift sobre SQLite. | Spike CRUD/migraciones/rendimiento/licencia en F1.6; `pubspec.lock` al integrar. Ver [ADR-005](docs/adr/ADR-005-persistencia-drift.md). |
| 6. Red | Aprobado como selección arquitectónica (2026-11-08) | Dio. | Timeout, cancelación, errores, fakes y licencia por validar en F1.8/F5. Ver [ADR-006](docs/adr/ADR-006-red-dio.md). |
| 7. Secretos | Aprobado como selección arquitectónica (2026-11-08) | flutter_secure_storage detrás de puerto de plataforma. | Mecanismos/licencias por SO y pruebas de guardar/borrar por validar en F1.9. Ver [ADR-007](docs/adr/ADR-007-secretos-flutter-secure-storage.md) y [ADR adicional A09](docs/adr/additional/ADR-A09-almacen-seguro.md). |
| 8. Catálogo | Aprobado como selección arquitectónica (2026-11-08) | AniList GraphQL, cliente propio, sin codegen. | Contrato/API/consultas/errores por verificar en F1.8; ver [ADR-008](docs/adr/ADR-008-anilist-graphql.md). |
| 9. Sync backend | Aprobado como referencia (2026-11-08); uso condicionado | Supabase (Postgres + Auth + RLS). | Probar auth, RLS, offline, minimización, transporte y política de datos antes de F5; sin video. Ver [ADR-009](docs/adr/ADR-009-backend-supabase.md) y [A11](docs/adr/additional/ADR-A11-sincronizacion-fakeremote.md). |
| 10. QR | Aprobado como selección arquitectónica (2026-11-08) | qr_flutter genera; mobile_scanner escanea solo Android. | Licencias, permisos y ciclo de vida por validar en F5. Ver [ADR-010](docs/adr/ADR-010-qr.md). |
| 11. Temas | Aprobado como selección arquitectónica (2026-11-08) | Motor propio con ThemeExtension. | Fallback, accesibilidad y seguridad de packs por validar en F3. Ver [ADR-011](docs/adr/ADR-011-temas.md). |
| 12. Subtítulos | Aprobado como selección arquitectónica (2026-11-08) | Estilo mediante propiedades de mpv. | Propiedades expuestas y efecto por validar en F2.6. Ver [ADR-012](docs/adr/ADR-012-subtitulos-mpv.md). |
| 13. Tests | Aprobado como estrategia (2026-11-08) | flutter_test + fakes manuales. | Validar contratos/fakes del núcleo en F1.12. Ver [ADR-013](docs/adr/ADR-013-pruebas.md). |
| 14. Empaquetado Linux | Aprobado como formato principal propuesto de distribución | Flatpak. | Manifest, permisos, codecs/licencias y actualización por validar en F5.1; no es autorización de release. Ver [ADR-014](docs/adr/ADR-014-empaquetado-flatpak.md). |
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
