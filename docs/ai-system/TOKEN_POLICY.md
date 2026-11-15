# Política de contexto y tokens

## Política aplicada

Optimizar recuperación, duplicación y razonamiento por tarea. Los perfiles del proyecto y la configuración local no fijan modelo ni esfuerzo; Codex los hereda del chat principal según la precedencia documentada. No reducir capacidad por una cuota fija: ahorrar mediante contexto conciso, búsquedas dirigidas, delegación pertinente y reutilización de resultados. Fuente: [configuración de subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents).

- Instrucciones raíz compactas; políticas detalladas se leen bajo demanda.
- Búsqueda inicial: hasta 5 fragmentos y 4000 caracteres; ampliar por evidencia, no por rutina.
- Handoff inicial: 6000 caracteres, con referencias y marcas de truncamiento.
- Subagentes con contexto autosuficiente breve, propiedad de archivos y un resultado verificable; reutilizarlos para seguimientos relacionados.
- Buscar con `rg` antes de abrir archivos, excluir cachés y limitar salida. No leer el repositorio completo ni páginas enteras.
- Investigar primero en memoria vigente. No repetir pruebas o auditorías sin cambios o duda concreta.
- Una reparación automática como máximo por ejecución del runner actual; no prometer tres intentos efectivos por aceptar `max_attempts <= 3`.

No se omiten verificaciones relevantes para cumplir un presupuesto. Si hace falta ampliar contexto, hacerlo y explicar la causa en el episodio.

## Opciones reales comprobadas

CLI 0.167.0: `--model`, `-c`, `--oss`, `--local-provider`, JSONL, ejecución efímera y reanudación aparecen en ayudas. La referencia oficial describe `model_reasoning_effort` y `model_auto_compact_token_limit`; se dejan sin fijar para heredar valores del modelo. No se inventan umbrales ni se desactiva compactación. Las preferencias administradas prevalecen.

La caché de prompts del proveedor no se fuerza mediante un parámetro local inventado. Mantener instrucciones estables puede favorecer reutilización, pero la tasa real depende de la plataforma. La memoria Markdown es portable y complementa la compactación del historial; no la sustituye.

## Medición

`autonomy.py` resume `turn.completed.usage` cuando Codex lo emite: entrada, salida y entrada cacheada. Cuenta eventos de herramientas completadas y mide tiempo. Un dato ausente es `null`, no cero. No suma entrada cacheada como tokens adicionales a entrada total. No estima precio sin una tarifa y modelo verificados. Los eventos no equivalen necesariamente a llamadas HTTP; número de llamadas al modelo y coste quedan no disponibles cuando no se exponen.

La evaluación de recuperación compara la misma pregunta con lectura documental completa y con fragmentos FTS5: documentos, caracteres, proxy `ceil(caracteres/4)`, tiempo, precisión y acierto de fuente. El proxy no es un tokenizer ni facturación y no mide ahorro total de una conversación. Ver `EVALUATION.md` para resultados reales.

Fuentes: [referencia de configuración](https://learn.chatgpt.com/docs/config-file/config-reference) y [eventos de ejecución no interactiva](https://learn.chatgpt.com/docs/non-interactive-mode). No afirmar ahorro exacto o calidad idéntica sin una medición comparable.
