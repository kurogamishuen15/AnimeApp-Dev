# F2.1 — Evaluación del reproductor

Fuente: documentación primaria de paquetes/upstream y memoria del proyecto
Fecha: 2026-11-09
Módulo: arquitectura de reproducción
Estado: requiere revisión
Decisión: continuar con media_kit/libmpv como candidato para F2.2; mantener único adaptador
Evidencia: [evaluación F2.1](../../architecture/F2.1-player-evaluation.md), [ADR-002](../../adr/ADR-002-motor-video.md), [auditoría F0.1](../../environment/F0.1-FEDORA.md)

## Resultado

La evaluación de fuentes primarias confirma que media_kit publica soporte GNU/Linux, usa libmpv y declara MIT para sus wrappers. La evidencia local registra `libmpv` 2.5.0 disponible en Fedora 44 mediante pkg-config. El upstream de mpv indica licencias GPLv2+ por defecto y modo LGPLv2.1+ condicionado a build sin componentes GPL y dependencias compatibles. La licencia exacta del runtime distribuible no queda establecida por la mera presencia de la biblioteca del sistema.

La arquitectura de referencia mantiene UI Flutter → Playback Session → Controls/Engine/Progress → MediaKit Adapter único → libmpv. El contrato interno permanece para F2.5; no se implementaron clases/código del reproductor.

## Límites y pendiente

No se añadieron paquetes, no se tocó `pubspec.yaml`/lockfile, no se ejecutó un reproductor ni se abrió medio local o remoto. Por tanto, plataforma, renderizado, cierre y rendimiento de reproducción no están verificados. El `NEVRA`, configuración de compilación y avisos del artefacto Fedora/Flatpak siguen pendientes. Se recomienda F2.2 para el spike local; la distribución conserva auditoría de dependencias/licencias para F5.

Las instrucciones F2.1 y F2.2 adjuntas se leyeron posteriormente tras autorización expresa. Aportan criterios técnicos para el trabajo del reproductor, pero el propietario confirmó que son documentos de referencia y no autorizan implementarlo ahora. Esta sesión conserva su alcance original de evaluación documental; no se añadieron dependencias, código ni reproducción.
