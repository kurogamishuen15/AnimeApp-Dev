# Equipo de desarrollo de AnimeApp

## Alcance obligatorio: solo esta carpeta

La ubicación autorizada para inspeccionar, buscar, ejecutar, crear o modificar archivos del proyecto es la raíz Git `PROYECTO ANIME` dentro de `Vídeos` y sus subcarpetas. Antes de cada tarea, confirma esa raíz. No recorras el directorio padre ni busques archivos por cuenta propia en otras carpetas, incluidos Imágenes, Documentos, Descargas, otros proyectos, el hogar del usuario o unidades externas. No sigas enlaces simbólicos que salgan del proyecto. Los cambios de código y documentación del proyecto deben permanecer dentro de esta raíz.

Los mensajes del chat del usuario son instrucciones directas y deben ejecutarse según su alcance, sin exigir una copia como archivo del repositorio. Los adjuntos enviados expresamente por el usuario pueden leerse directamente desde la ruta que la plataforma proporciona, en modo de solo lectura; esto no autoriza explorar archivos vecinos ni otros documentos personales. Respeta siempre los permisos reales del sandbox. No inventes rutas ni presupongas que un mensaje de instrucciones corresponde a un archivo. Si falta material realmente necesario y no fue proporcionado en el chat ni como adjunto, explica la dependencia concreta sin buscar fuera de las ubicaciones autorizadas.

No accedas a otro repositorio ni a documentos personales no autorizados. No infieras tecnologías o pruebas de AnimeApp a partir del nombre del proyecto.

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
| monitoreo | Solicitud de resumen de métricas, CI o reportes de ejecución; nunca daemon. |
| investigador | Datos cambiantes, investigación externa o verificación de fuente primaria. |
| auditor_dependencias | Cambios o revisión de versiones, licencias y cadena de suministro. |
| auditor_rendimiento | Perfilado, CPU/RAM, latencia o recursos que no se liberan. |
| auditor_arquitectura | Revisión independiente de límites modulares y ADRs. |
| auditor_contratos | APIs y compatibilidad entre módulos o servicios. |
| auditor_accesibilidad | Auditoría de navegación, foco, semántica y accesibilidad. |
| auditor_release | Preparación de empaquetado, avisos, licencias y publicación. |
| diagnostico_logs | Logs o fallos que necesiten clasificación y reproducción. |
| gestor_cola | Solicitud de priorizar tareas, dependencias y criterios de cierre. |

Concurrencia conservadora: un especialista simultáneo en sesiones nuevas; respetar límites administrados y RAM disponible. Los perfiles omiten `model` y `model_reasoning_effort`, y `.codex/config.toml` no fija valores predeterminados; Codex hereda el modelo y esfuerzo del chat principal/coordinador. Sin subdelegación. Cada encargo lleva contexto mínimo autosuficiente, objetivo, archivos de propiedad exclusiva, restricciones y validación. No reenviar conversaciones completas. No sobrescribir ni revertir trabajo ajeno. Auditorías independientes en solo lectura. Los perfiles son bajo demanda, no procesos residentes.

## Capacidad, seguridad y cierre

Heredar modelo, razonamiento y permisos; no reducir capacidad solo para ahorrar tokens. Reducir lecturas, duplicación y salida; reutilizar resultados vigentes. Ampliar contexto cuando la evidencia lo exija. No prometer ahorro absoluto.

No usar permisos irrestrictos, modificar Fedora, instalar servicios residentes, leer/transmitir credenciales ni hacer push/publicar sin autorización específica. No interpretar ausencia como aprobación. Un modo nocturno solo está listo tras prueba real de aislamiento y proveedor. Si falta un prerrequisito, registrar bloqueo y continuar tareas independientes seguras. Seguir el procedimiento de Git/commits locales del runbook, incluyendo comprobación de cambios previos.

La memoria es persistente en archivos; los agentes solo se activan durante solicitudes o ejecuciones explícitas. No prometer procesos residentes ni supervivencia a reinicios.

## KONGROO — Mandatory Quality and Audit Gates

These gates apply to every module and phase across this repository.

- Before implementing material technical uncertainty, inspect existing code/architecture and current primary documentation; compare claims with installed versions. Respect approved layer boundaries and keep affected READMEs/contracts synchronized.
- After substantial implementation, on audit request, before recommending subphase closure, and for media, public-contract, dependency, persistence, concurrency, or resource-lifecycle changes, follow `.agents/skills/kongroo-deep-audit/SKILL.md`.
- Audit critically with relevant tests and negative/concurrent cases. Distinguish compilation from behavior, fakes from real integrations, historical evidence from checks run now, and verified findings from risks. Never claim an unrun check.
- Do not recommend acceptance with unresolved P0/P1 findings, unmet criteria, missing essential evidence, confirmed regressions, or critical documentation gaps. The owner makes the final acceptance decision. Do not mark a phase complete or advance automatically.
- Use an independent `auditor_codigo` review sequentially when useful; otherwise make a separate second pass and disclose its limits. No unnecessary parallel auditors.
- No commit or push without explicit authorization.
