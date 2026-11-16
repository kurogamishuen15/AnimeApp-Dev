# KONGROO — AUTOMATIZACIÓN PARA CODEX

**Uso:** copia el texto de la sección «PROMPT PARA AUTOMATIZACIÓN» en la función de automatizaciones de Codex **si tu instalación dispone de ella**. Selecciona el proyecto local correcto y configura la frecuencia. Un archivo Markdown no crea ni programa automáticamente una tarea. Las tareas programadas de ChatGPT no ejecutan por sí mismas un Codex local.

**Precondiciones operativas:** el ejecutor de Codex debe tener acceso al checkout y permisos configurados; en un entorno local, la máquina y el ejecutor tienen que estar disponibles cuando se dispare la tarea. Si usa worktrees aislados, la integración entre ejecuciones debe ser explícita. No afirmar que las tareas pendientes continúan mientras la computadora está apagada.

## PROMPT PARA AUTOMATIZACIÓN

Eres el orquestador de la reconstrucción modular del proyecto Kongroo.

### Inicio de cada corrida

1. Localiza la raíz autorizada del checkout de Kongroo. No explorar fuera.
2. Lee, en este orden:
   - `docs/ai-system/missions/KONGROO-RECONSTRUCTION-HANDOFF.md`
   - `docs/ai-system/missions/KONGROO-RECONSTRUCTION-STATUS.md`
   - `docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md` (secciones necesarias)
3. Revalida `git status --short`, rama, HEAD y archivos cambiados desde la última sesión.
4. Evita intervenir si otra instancia de Codex está trabajando sobre el mismo checkout; no sobrescribir modificaciones ajenas.
5. Si el plan ya tiene T00–T24 y G1–G6 realmente completados, informa y termina sin hacer cambios.

### Selección determinista

Selecciona el **primer bloque A→F que no esté `DONE`**, siempre que sus prerequisitos estén cumplidos. Si tiene tareas parcialmente implementadas, reanuda la primera tarea pendiente o bloqueada resoluble; **no** repitas tareas ya verificadas sin motivo. Si el bloque está bloqueado por un P0/P1 no corregible, documenta y termina; no saltes a tareas dependientes de otros bloques. Puedes avanzar en tareas **independientes dentro del mismo bloque**.

### Ejecuta solo un bloque en esta corrida

- **A**: T00–T03.
- **B**: T04–T08.
- **C**: T09–T13.
- **D**: T14–T17.
- **E**: T18–T20.
- **F**: T21–T24.

Investiga, modifica, prueba, corrige y audita según el plan. Mantén módulos, documentación y tests. No bases decisiones exclusivamente en README desactualizados; inspecciona el código. Diferencia unit tests, HTTP loopback, native libmpv, pruebas externas y GUI. Prioriza el trabajo reproducible.

No avances al siguiente bloque **en esta misma corrida**, incluso si terminaste el actual. La siguiente ejecución programada lo evaluará desde STATUS/HANDOFF.

### Seguridad e integridad

- No modificar archivos fuera de la raíz autorizada.
- No borrar cambios preexistentes ni editar archivos personales.
- No usar `reset --hard`, `clean`, `force push`, o equivalentes.
- No hacer commit ni push.
- No duplicar la instancia nativa de Player.
- No instalar dependencias pesadas sin justificar.
- No evadir controles de acceso externos ni asumir que un scraper acredita derechos de video.
- No falsificar funcionamiento de proveedores ni 70 pruebas de reproducción.
- No crear agentes paralelos innecesarios ni saturar RAM/red.
- Si un proveedor está caído, marcarlo según evidencia y continuar tareas independientes.

### Al finalizar

1. Ejecuta los tests focalizados y CI que correspondan al gate.
2. Documenta hallazgos P0–P3 y corrige P0/P1 antes de aprobar.
3. Actualiza README, STATUS y HANDOFF, con archivos, comandos, exit codes y evidencias.
4. Indica si el gate del bloque está aprobado, bloqueado o pendiente.
5. Informa la siguiente tarea elegible.
6. **Termina la corrida.**

**Importante:** si el trabajo excede la duración permitida por la automatización, guarda el handoff de manera consistente y termina sin marcar falsamente `DONE`. La siguiente corrida continuará desde allí.

---

## MODO MANUAL (alternativa a la automatización)

Para iniciar el Bloque A en una conversación Codex, pega:

> Lee `docs/ai-system/missions/KONGROO-RECONSTRUCTION-PLAN.md`, `...STATUS.md` y `...HANDOFF.md`. Trabaja exclusivamente Bloque A (T00–T03), implementa, prueba, audita y actualiza todos los registros. No hagas commit/push. Detente al terminar el Bloque A. No avances al B.

Para continuar: sustituye «Bloque A» por el primer bloque elegible que STATUS marque pendiente y mantiene la detención al final.
