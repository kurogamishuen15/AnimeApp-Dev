# Equipo de desarrollo de AnimeApp

## Alcance obligatorio: solo esta carpeta

La única ubicación autorizada para inspeccionar, leer, buscar, ejecutar, crear o modificar archivos es la carpeta actual `PROYECTO ANIME` dentro de `Vídeos`, y sus subcarpetas. Antes de cada tarea, confirma que el directorio de trabajo es esta raíz. No recorras el directorio padre ni otras rutas. No inspecciones, listes, abras ni busques archivos en otras carpetas, incluidas Imágenes, Documentos, Descargas, otras carpetas de proyectos, el hogar del usuario o unidades externas. No sigas enlaces simbólicos que salgan del proyecto. Si una tarea parece depender de algo fuera de esta raíz, detente en esa dependencia, documenta el bloqueo y solicita que el material se coloque dentro del proyecto; no lo busques por tu cuenta.

No accedas a otro repositorio ni a documentos personales. Esta misión configura infraestructura de IA; no autoriza funciones de producto. No infieras tecnologías o pruebas de AnimeApp a partir del nombre del proyecto.

## Inicio y memoria

1. Leer docs/memory/PROJECT_STATE.md y consultar el índice relevante.
2. Buscar con `python3 tools/ai/memory.py search "términos" --max-chars 4000` o rg; abrir solo fuentes pertinentes. Verificar fecha, estado y evidencia.
3. Antes de editar: comprobar Git, preservar trabajo previo y respaldar cualquier configuración existente.
4. Trabajar y ejecutar validaciones pertinentes. No declarar pruebas verdes sin evidencia.
5. Actualizar estado, episodio/decisión afectada y AI_HANDOFF.md. Ejecutar `python3 tools/ai/memory.py check`. No convertir hipótesis en decisiones.

Índices: docs/memory/ARCHITECTURE_INDEX.md, MODULE_INDEX.md, DECISIONS.md, RESEARCH_INDEX.md. Políticas detalladas: docs/ai-system/README.md, AUTONOMY_POLICY.md, RUNBOOK.md, FINAL_REPORT.md.

## Git, contribuciones y publicaciones

- La raíz Git es esta carpeta; no inicializar repositorios anidados.
- La política de ramas, Conventional Commits y revisión de cambios está en [CONTRIBUTING.md](CONTRIBUTING.md).
- El flujo futuro de versiones y publicación pública está en [RELEASING.md](RELEASING.md). No publicar, crear remotos ni cambiar visibilidad sin autorización explícita.
- La configuración compartible de agentes está en `.codex/agents/`. `.codex/config.toml` es local y no se versiona. Revisar archivos y secretos antes de preparar cambios; `.gitignore` no reemplaza esa revisión.
- Mantener `pubspec.lock` cuando se inicialice la aplicación Flutter. Versionar configuraciones y manifiestos necesarios para reproducir compilaciones.
- Consultar `docs/memory/PROJECT_STATE.md` y `docs/memory/AI_HANDOFF.md` para conocer el estado confirmado; no inferir que una fase o prueba se completó por aparecer en el plan.

## Activación automática

El usuario autoriza delegación automática pertinente. El coordinador es el orquestador y verifica entregas. Usar .codex/agents/ o transmitir sus instrucciones si el entorno no los carga. No activar agentes sin una tarea concreta ni delegar tareas triviales.

| Agente | Activar ante |
| --- | --- |
| planificador | Objetivos amplios, fases, prioridades y dependencias. |
| arquitecto | Arquitectura, contratos e investigación técnica compleja. |
| ux_ui | Flujos, diseño y accesibilidad. |
| frontend | Interfaz y estado del cliente. |
| backend | API, servicios y lógica de negocio. |
| datos | Persistencia, consultas y migraciones. |
| qa | Reproducción y verificación de comportamiento. |
| auditor_codigo | Auditoría solicitada o cambios sustanciales. |
| seguridad | Permisos, secretos, datos sensibles y entradas no confiables. |
| devops | Entornos, CI, aislamiento y compilación. |
| documentacion | Memoria, instalación, uso, contratos y traspasos. |

Concurrencia conservadora: un especialista simultáneo en sesiones nuevas; respetar límites administrados y RAM disponible. Sin subdelegación. Cada encargo lleva contexto mínimo autosuficiente, objetivo, archivos de propiedad exclusiva, restricciones y validación. No reenviar conversaciones completas. No sobrescribir ni revertir trabajo ajeno. Auditorías independientes en solo lectura.

## Capacidad, seguridad y cierre

Heredar modelo, razonamiento y permisos; no reducir capacidad solo para ahorrar tokens. Reducir lecturas, duplicación y salida; reutilizar resultados vigentes. Ampliar contexto cuando la evidencia lo exija. No prometer ahorro absoluto.

No usar permisos irrestrictos, modificar Fedora, instalar servicios residentes, leer/transmitir credenciales ni hacer push/publicar sin autorización específica. No interpretar ausencia como aprobación. Un modo nocturno solo está listo tras prueba real de aislamiento y proveedor. Si falta un prerrequisito, registrar bloqueo y continuar tareas independientes seguras. Seguir el procedimiento de Git/commits locales del runbook, incluyendo comprobación de cambios previos.

La memoria es persistente en archivos; los agentes solo se activan durante solicitudes o ejecuciones explícitas. No prometer procesos residentes ni supervivencia a reinicios.
