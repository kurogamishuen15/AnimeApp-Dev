# ADR-011: Sistema de temas

- Fuente: plan maestro, sección 3 (lista suministrada por el propietario el 2026-11-08).
- Estado: **Principio aprobado en `TECH_DECISIONS.md`; motor ThemeExtension aún no consta aprobado**.
- Fase: F3.1 y packs F3.6.
- Requisitos: NFR-10; UI y temas excluidos de F1.

## Contexto

El proyecto ya registra packs opcionales validados, sin código ejecutable, y modo Lite independiente. La sección 3 especifica ThemeExtension como mecanismo del motor propio.

## Propuesta

Implementar el motor de tema propio usando `ThemeExtension` de Flutter para tokens/valores semánticos, manteniendo validación de packs y sin código ejecutable. Lite se mantiene como perfil funcional independiente del pack visual.

## Consecuencias y aceptación

No implementar en F1. En F3 validar temas claro/oscuro/contraste si se aprueba, extensiones completas, fallback para claves ausentes y que contenido de pack no ejecute código. La biblioteca/custom renderer adicional no está seleccionada.
