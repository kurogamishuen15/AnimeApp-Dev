# ADR-014: Empaquetado de Linux

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Flatpak aceptado por el propietario como formato principal propuesto para distribución; empaquetado/publicación no autorizados ahora**.
- Fase: F5.1, empaquetado Fedora/Linux.
- Requisitos: NFR-06; no empaquetar durante F1.

## Propuesta

Mantener Flatpak como formato principal propuesto de distribución Linux. Esto no excluye desarrollar/ejecutar el scaffold localmente con el toolchain habitual ni define aún canal, tienda, runtime o permisos.

## Alternativas

- RPM del sistema: alternativa de distribución secundaria sujeta a mantenimiento/target.
- AppImage/deb: no seleccionados por el plan maestro.

## Consecuencias y aceptación

En F5 revisar manifest, runtime, permisos mínimos, codecs/libmpv/plugins, licencias y reproducibilidad. Probar instalación/ejecución/actualización/desinstalación en Fedora objetivo y registrar cómo se reciben actualizaciones. No distribuir el paquete sin aprobación de release.
