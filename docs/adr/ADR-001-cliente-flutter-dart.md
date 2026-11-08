# ADR-001: Cliente Flutter y Dart

- Correspondencia: decisión 1 de la sección 3 del plan maestro.
- Estado: **Aceptado en F0.4**
- Fecha: 2026-11-08
- Evidencia: `TECH_DECISIONS.md`, `docs/environment/F0.1-FEDORA.md`, `PROGRESS.md`
- Requisitos: NFR-01, NFR-06

## Contexto

El proyecto comienza en Fedora/Linux y prevé Android, Android TV y Windows. El scaffold Flutter/Dart y el toolchain Linux quedaron verificados en F0.1/F0.4; `flutter analyze` conserva un fallo LSP documentado para la ruta no ASCII.

## Decisión

Se conserva Flutter como framework de UI y Dart como lenguaje de la aplicación, el dominio y casos de uso portables. Esta decisión no implica que Android, Android TV o Windows estén ya verificados.

## Alternativas consideradas

- Implementaciones separadas por plataforma: mayor duplicación para el alcance actual.
- Toolkit de escritorio nativo: no corresponde a la estrategia multiplataforma aprobada.

## Consecuencias

El dominio debe permanecer Dart puro; plugins y APIs nativas se encapsulan detrás de puertos. La falla actual del analyzer se sigue como limitación de toolchain y no se silencia.

## Aceptación y verificación

Mantener el análisis Dart y la verificación de imports; en F1.4 comprobar que dominio/casos de uso no importan Flutter. Verificar cada plataforma al incorporarla.
