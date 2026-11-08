# ADR-010: Generación y escaneo de QR

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Especificado en el plan; aprobación formal no consta en el registro local**.
- Fase: flujo de vinculación/plataformas F5; escaneo restringido a Android según plan.
- Requisitos: fuera del alcance de F1; revisar permisos/ciclo de vida antes de F5.

## Propuesta

Usar `qr_flutter` para generar códigos y `mobile_scanner` para escanearlos solo en Android. El contrato de vinculación no depende de widgets/plugins y generación/escaneo se aíslan en adaptadores.

## Alternativas

- Generación vectorial propia solo si el paquete no satisface renderizado/licencia.
- Escaneo nativo por plataforma solo si el plugin no cumple requisitos comprobados.

## Consecuencias y aceptación

No añadir paquetes en F1. Antes de F5, verificar licencias/mantenimiento, permisos de cámara mínimos, autorización Android, ciclo de vida al pausar/resumir y manejo de payload inválido. No declarar escaneo en Linux, Windows o iOS: la decisión del plan limita mobile_scanner a Android.
