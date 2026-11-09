# ADR-015: Núcleo compartido y Linux primero

- Estado: **Aceptado por el propietario para F1.3**
- Fecha: 2026-11-08
- Decisión: Fedora/Linux primero; núcleo Dart reutilizable; adaptadores progresivos por plataforma
- Sustituye: ninguno
- Complementa: [ADR adicional A01, capas y dependencias](additional/ADR-A01-arquitectura-por-capas.md)
- Diseño detallado: [ARCHITECTURE.md](../../ARCHITECTURE.md)

## Contexto

F1.3 necesita convertir los principios de capas en límites utilizables para el diseño y la estructura futura. El propietario estableció Fedora/Linux como destino de implementación y validación inicial y Android, Android TV y Windows como plataformas posteriores. El dominio y la lógica general deben poder reutilizarse sin replicación.

La aplicación tiene solamente un esqueleto Flutter/Linux: `main.dart`, `AnimeApp`, identidad Dart pura y runner Linux. No hay funcionalidades de catálogo, persistencia, navegación ni reproducción implementadas. Crear de antemano adaptadores o módulos vacíos elevaría el mantenimiento y no responde a una necesidad actual.

## Decisión

1. Implementar primero para Fedora/Linux, preservando un núcleo compartido Dart.
2. Mantener dominio y aplicación independientes de Flutter UI, Linux, plugins, servicios y detalles de infraestructura.
3. Conectar presentación, casos de uso, contratos y adaptadores mediante composición; las implementaciones externas dependen de contratos, no al revés.
4. Añadir un adaptador solo ante una diferencia real de plataforma/dependencia y un consumidor concreto.
5. No crear durante las fases Linux iniciales código, carpetas, servicios, interfaces o dependencias exclusivos de Android, Android TV o Windows.
6. Mantener módulos con tamaño razonable: separar por responsabilidad, estado, pruebas, reutilización, variación o dependencias; permitir archivos compartidos para componentes pequeños cohesionados.
7. Documentar cada módulo importante junto con su implementación mediante la guía de contenido de `ARCHITECTURE.md`, incluyendo portabilidad y límites de plataforma.
8. F1.4 implementará únicamente el esqueleto Linux y contratos compartidos que sus criterios requieran; la estructura candidata no obliga a crear carpetas vacías.

## Alternativas consideradas

- Crear desde ahora adaptadores/servicios para los cuatro destinos: rechazado por anticipar necesidades no verificadas y añadir código/dependencias sin uso.
- Replicar lógica general por plataforma: rechazado porque crea divergencia funcional y mantenimiento duplicado.
- Crear un framework de interfaces para toda capacidad potencial: rechazado; cada puerto requiere necesidad y consumidor demostrables.
- Concentrar todo en una aplicación Linux monolítica: rechazado porque acoplaría dominio y lógica al host/UI y dificultaría pruebas y evolución.

## Consecuencias y límites

- La arquitectura mantiene reutilizable la lógica general y contiene las dependencias de sistema.
- Linux recibe validación primero; plataformas futuras requieren su propio análisis de compatibilidad, UI, controles, rendimiento y tamaño.
- No se garantiza que cada plugin aprobado funcione idénticamente en todos los destinos. Compatibilidad, licencias y seguridad siguen siendo validaciones por fase.
- `media_kit`/libmpv solo se integra tras validación real y detrás de `PlaybackEngine`; `mobile_scanner` permanece Android-only. No instalar dependencias por la aprobación arquitectónica.
- La persistencia sigue local-first; Supabase requiere validación Auth/RLS y nunca alojará video. Flatpak sigue como formato Linux principal propuesto.
- Los objetivos de rendimiento son preliminares hasta mediciones reproducibles; la modularidad/tree shaking no sustituyen mediciones.
- La estructura de F1.4 es propuesta hasta que esa subfase determine archivos mínimos y criterios; este ADR no implementa código.

## Verificación y revisión

En F1.4 revisar el grafo real de imports para confirmar que dominio/aplicación no dependen de Flutter o plugins, que solo se crean módulos usados y que el runner sigue siendo Linux. Al iniciar una plataforma futura, inventariar adaptadores necesarios, demostrar reutilización de la lógica común, ejecutar paridad funcional y registrar medidas de rendimiento/tamaño. Revisar este ADR si evidencia concreta demuestra que una dependencia común o el límite Linux-first impide un requisito aprobado.
