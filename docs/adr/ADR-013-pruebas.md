# ADR-013: Estrategia de pruebas

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Herramienta parcialmente usada en F0; estrategia de fakes manuales especificada en plan, aprobación formal no consta**.
- Fase: F1.12 para núcleo; pruebas de reproducción/UI en F2–F4.
- Requisitos: NFR-09, NFR-10.

## Decisión propuesta

Usar `flutter_test` para pruebas Flutter/widgets y fakes escritos a mano para puertos externos. Las reglas del dominio usan tests Dart puros cuando no requieran harness Flutter. No contactar red/servicios en pruebas por defecto.

## Alternativas

- Mocks generados: plan no los selecciona; evaluar solo si el costo de fakes manuales se vuelve desproporcionado.
- Pruebas con servicios reales: reservadas a verificación explícita y entorno controlado; no son suite normal.

## Consecuencias y aceptación

En F1.12 compartir pruebas de contrato entre repositorios/fakes y cubrir errores, offline e integridad. F0 ya usa `flutter_test` para el widget test; eso no equivale a validar aún la estrategia del núcleo. Cada fake debe ser determinista y mantener comportamiento verificable.
