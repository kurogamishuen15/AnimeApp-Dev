# Decisiones técnicas de AnimeApp

Registro compacto de decisiones aprobadas y propuestas pendientes. Las decisiones de esta página no sustituyen ADR detallados futuros.

| Tema | Estado | Decisión o propuesta | Consecuencia / evidencia pendiente |
| --- | --- | --- | --- |
| Cliente | Aprobado para F0.4 | Flutter y Dart para el cliente multiplataforma. | Fedora 44/toolchain Linux verificados en F0.1; Flutter 3.47.9 aún reproduce un fallo LSP de analyze en ruta no ASCII. |
| Reproductor | Aprobado como punto de partida | UI propia; `media_kit` + `media_kit_video` sobre libmpv detrás de `PlaybackEngine`. | Confirmado por el usuario; compatibilidad y rendimiento reales aún no probados. No incluir en F0.4. |
| Reproductor nativo directo | Alternativa futura | FFI/integración directa solo si se demuestra limitación de media_kit. | No se presume menor consumo. |
| Datos locales | Propuesta | Drift/SQLite. | Pendiente de aprobación e integración en F1. |
| Estado/navegación/red | Propuestas | Riverpod, go_router, Dio. | Pendientes de validar y aprobar; evitar dependencias en F0.4. |
| Sincronización | Principio aprobado | Local primero; backend detrás de contrato REST, no requerido para operación offline. | Proveedor/servicio remoto aún por aprobar e implementar. |
| Proveedores | Principio aprobado | Adaptadores aislados; mock primero; fuentes reales desactivadas hasta evaluación técnica/legal. | Contratos se verifican en F2. |
| Repositorios | Aprobado | `AnimeApp-Dev` privado; `AnimeApp` público, vacío hasta versión aprobada; historial público independiente. | Publicación futura por selección explícita de archivos y aprobación manual. |
| Commits | Aprobado | Conventional Commits; rama de desarrollo `main`; commit final por subfase cuando sea práctico. | Identidad privada configurada solo en Git local. |
| D3 — Licencia del proyecto | Pendiente | No se ha seleccionado licencia ni creado un archivo LICENSE. | No bloquea F0.3; resolver antes de distribuir código o binarios y revisar licencias de dependencias. |
| Temas | Principio aprobado | Packs opcionales, validados y sin código ejecutable; Lite independiente. | Implementación posterior en F3. |

## Licencia del proyecto

La licencia aún no está decidida. No se publica ni se crea un `LICENSE` provisional que pueda confundirse con una licencia válida. D3 es una decisión pendiente del propietario y no bloquea F0.3; debe resolverse antes de distribuir.

## Reglas para modificar decisiones

Una propuesta no se convierte en decisión por aparecer en el plan. Para una decisión arquitectónica nueva registrar problema, alternativas, consecuencias y pruebas requeridas; no modificar decisiones confirmadas sin autorización.
