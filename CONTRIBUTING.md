# Contribuir a AnimeApp

Esta guía describe cómo preparar cambios en el repositorio privado de desarrollo. La publicación pública se gestiona por separado y requiere aprobación del propietario; consulta [RELEASING.md](RELEASING.md).

## Antes de empezar

Lee [AGENTS.md](AGENTS.md), el estado actual en `docs/memory/PROJECT_STATE.md` y la documentación del módulo que vayas a tocar. Comprueba la raíz, rama y estado de Git. Conserva cambios existentes y no incluyas archivos sin revisar.

No guardes contraseñas, tokens, claves privadas, datos de usuario ni credenciales reales en Git. `.gitignore` evita inclusiones accidentales conocidas, pero cada contribución requiere revisar los archivos preparados. No modifiques la configuración global de Git.

## Repositorios

- `AnimeApp-Dev` será el repositorio privado principal: código de desarrollo, pruebas, documentación y experimentos aprobados.
- `AnimeApp` será el repositorio público de versiones aprobadas. No recibe automáticamente commits ni el historial privado.
- No configures remotos, crees repositorios ni publiques cambios sin autorización explícita.

## Ramas

La rama principal de desarrollo es `main`. Usa ramas breves cuando el cambio lo amerite:

- `feature/<tema>` para funcionalidades.
- `fix/<tema>` para correcciones.
- `refactor/<tema>` para cambios estructurales.
- `docs/<tema>` para documentación.
- `release/<version>` para preparar una candidata pública.

Las tareas pequeñas pueden usar el flujo acordado para `main`; no abras ramas por rutina. La regla general es un commit final por subfase aprobada, con commits intermedios cuando faciliten revisión o recuperación.

## Commits

Usa Conventional Commits con el formato `tipo(alcance): descripción`, por ejemplo:

```text
feat(player): añadir controles de reproducción
fix(player): liberar recursos al cerrar la sesión
perf(catalog): limitar imágenes precargadas
refactor(core): separar el contrato del motor
docs(architecture): explicar los límites de módulos
test(player): cubrir el cambio de fuente
build(linux): ajustar el manifiesto de empaquetado
ci(github): validar análisis y pruebas
chore(repo): preparar base inicial de desarrollo (F0.2)
```

Tipos iniciales: `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore` y `revert`. El asunto debe describir el cambio real. Señala cambios incompatibles con `!` o una nota `BREAKING CHANGE`.

Antes de confirmar un cambio, ejecuta las comprobaciones pertinentes, actualiza documentación y progreso, revisa `git diff --check` y confirma que el índice contiene únicamente rutas esperadas. No uses `git add .` en el primer commit ni para preparar cambios compartidos.

## Pruebas y documentación

Sigue los comandos documentados para el módulo afectado. Registra qué se ejecutó y qué no pudo verificarse. Actualiza el README del módulo, decisiones o registros de rendimiento cuando el cambio lo requiera. Una funcionalidad queda completa solo cuando satisface sus pruebas, la revisión de rendimiento aplicable y la documentación de la subfase.

## Dependencias y licencias

Justifica dependencias antes de incorporarlas. Cuando exista la app Flutter, conserva `pubspec.lock` para reproducir versiones. Registra licencias y avisos de bibliotecas incluidas, en especial dependencias multimedia nativas, antes de distribuir una compilación.

## Proceso de revisión

Describe objetivo, alcance, archivos afectados, pruebas ejecutadas, resultados, limitaciones y pendientes. No marques fases como completas por tener documentación o interfaz solamente. Para publicar una versión sigue el proceso de aprobación en [RELEASING.md](RELEASING.md).
