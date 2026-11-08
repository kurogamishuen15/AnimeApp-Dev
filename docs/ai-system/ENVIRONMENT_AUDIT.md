# Auditoría inicial del entorno

Fecha: 2026-11-07, America/Bogota. Fuentes: inspección local de solo lectura, ayudas de ejecutables y auditorías delegadas. Estado: vigente para esta sesión; repetir `doctor` antes de una misión nocturna. No contiene credenciales.

## Alcance e integridad

El único proyecto autorizado es esta carpeta: `PROYECTO ANIME` dentro de Vídeos. El usuario excluyó expresamente otro repositorio localizado durante la búsqueda inicial; no se modificó ni se incorporó su contenido. Aquí no hay aplicación Flutter, `pubspec.yaml` ni arquitectura de producto verificable. Se construye infraestructura de desarrollo, sin funciones de AnimeApp.

Estado inicial: `AGENTS.md`, 11 perfiles `.codex/agents/*.toml`, configuración de agentes y directorios especiales `.agents`, `.aws`, `.git`. `git rev-parse` no reconoce un repositorio: `.git` se presenta vacío/protegido en la sesión. No hay rama, commits, cambios rastreados ni remotos verificables aquí. No inicializar ni sustituir `.git` sin comprobar el acceso al directorio real.

Antes de alterar archivos existentes se creó `.ai-local/backups/initial-20261107/` con copias de AGENTS y los 12 TOML y manifiesto SHA256 comprobado. Los respaldos permanecen locales y no se versionan. Se conservarán todos los archivos preexistentes.

## Inventario comprobado

| Componente | Evidencia local | Limitación |
| --- | --- | --- |
| Codex CLI | `~/.local/bin/codex`, 0.167.0; `--help` y `exec --help` funcionan | No demuestra autenticación ni una ejecución de modelo desatendida. |
| Git | `/usr/bin/git`, 2.56.0 | Esta carpeta todavía no es un repositorio operativo. |
| GitHub CLI | `~/.local/bin/gh`, 2.103.3 | No se leyó autenticación. |
| Flutter | SDK visible, caché declara 3.47.9 stable | Lanzador no puede escribir caché fuera del espacio autorizado; no se ejecutaron pruebas Flutter. |
| Dart | Binario directo del SDK, 3.13.7 stable | Lanzador comparte restricciones de caché. |
| Rust/Cargo | 1.99.1, visibles fuera de PATH | No son necesarios para esta infraestructura Python. |
| Node.js | `/usr/bin/node`, 22.23.1 | No se añade un servidor Node. |
| Python | `/usr/bin/python3`, 3.14.8 | Se usará biblioteca estándar y SQLite FTS5, comprobados por pruebas. |
| Podman | RPM 5.8.1-1.fc44 | Desde el aislamiento falla al crear `/run/user/1000/libpod`; contenedores aún no verificados. |
| tmux | `/usr/bin/tmux`, 3.6a | Una sesión persistente no equivale a supervivencia a reinicios. |
| Sistema visible | Fedora 44, Linux 6.19.10 | `systemd-detect-virt` indica `container-other`. |

Comandos base: `command -v`, ayudas y versiones, `rpm -q podman`, `lscpu`, `free -h`, `df -h`, `systemd-detect-virt`, `ps -eo comm,pcpu,pmem,rss`, `git rev-parse`. No se enumeraron variables de entorno ni se leyeron archivos de autenticación.

## Recursos y configuración

Instantánea inicial: CPU expuesta i5-1035G1, 4 núcleos/8 hilos; RAM 7.5 GiB, aproximadamente 1.9 GiB disponible; swap 7.5 GiB con 2.3 GiB utilizada; volumen 237 GiB con 207 GiB libres. `/tmp` 3.8 GiB. Son recursos visibles desde aislamiento, no una certificación del equipo físico. Cuotas cgroup y procesos completos del anfitrión no están disponibles. No corresponde asumir el i3/4 GB de referencia.

La configuración global se inspeccionó inicialmente con lista de claves permitidas: no fija modelo, esfuerzo, sandbox ni agentes. Declara `node_repl`; no se copiaron argumentos sensibles, variables ni credenciales. Las herramientas de esta sesión y los MCP personales son capas distintas. Tras la restricción del usuario no se modifica configuración personal.

Configuración compartida inicial: agentes habilitados, hasta tres subagentes. Los 11 perfiles heredan modelo/esfuerzo/permisos y prohíben subdelegación. Se comprobó además su carga: el entorno ofrece sus 11 nombres como tipos de agente. Las tres auditorías iniciales fueron delegaciones reales completadas.

Skills: 39 archivos, 38 nombres; dos versiones en caché de `visualize` (1.0.84 y 1.0.89). El catálogo de esta sesión selecciona 1.0.89. No se borran cachés ni skills ajenas al proyecto. Ningún duplicado obliga a instalar otra herramienta.

## Capacidades y límites

La CLI instalada anuncia `exec`, JSONL, esquema de salida, último mensaje, ejecución efímera, reanudación y sandbox de solo lectura/escritura del workspace. Las ayudas verifican sintaxis; solo una ejecución real puede acreditar modelo, autenticación y aislamiento. Se contrastan las opciones con [modo no interactivo oficial](https://learn.chatgpt.com/docs/non-interactive-mode) y [referencia de configuración](https://learn.chatgpt.com/docs/config-file/config-reference). Las políticas administradas de esta sesión tienen prioridad.

No se usarán permisos irrestrictos, servicios persistentes ni credenciales del hogar en contenedores. El modo nocturno debe bloquearse si no puede demostrar sus prerrequisitos. El estado final y los ensayos posteriores están en `EVALUATION.md` y `FINAL_REPORT.md`.

## Plan de mejoras y riesgos

1. Crear memoria Markdown portable con fuentes, fechas, estados y evidencia; índices y SQLite FTS5 derivado, sin embeddings residentes.
2. Reutilizar especialistas y reducir concurrencia compartida a uno, dada la presión de memoria visible. La selección no reduce modelo ni razonamiento.
3. Construir herramientas acotadas de búsqueda, validación, traspaso, métricas y ejecución aislada con rechazo seguro.
4. Evaluar MCP con pruebas públicas y seleccionar únicamente los que agreguen una capacidad comprobada; no duplicar conectores disponibles.
5. Probar recuperación, fallos, Git y ciclo integral en un proyecto de prueba inocuo. Diferenciar pruebas con dobles de una ejecución real de Codex.
6. Preparar recuperación por copias verificadas y commits locales, sin push. Inicializar Git solo dentro de esta carpeta autorizada cuando el acceso lo permita.

Riesgos principales: ausencia de código de producto, Git especial protegido, SDK fuera del espacio escribible, contenedores no utilizables desde la sesión, memoria disponible baja, métricas reales de la conversación no expuestas y posible falta de autenticación del ejecutor no interactivo. No ocultar estos límites con pruebas simuladas.
