# Evaluación reproducible

Fecha local: 2026-11-07, Bogotá. Ejecutar `python3 tools/ai/evaluate.py --write-report` desde la raíz. Detalle de consultas, documentos, precisión, tiempos y contexto: [evaluation.json](evaluation.json).

Línea base: 29 documentos, 57685 caracteres, 14422 tokens proxy, 0.621 ms de lectura mediana. Se compara la lectura completa del mismo corpus con tres consultas medidas por pregunta; la búsqueda incluye reconstrucción del índice. No se afirma que FTS sea más rápido que leer un corpus pequeño.

| Prueba | Resultado | Precisión fragmentos | ms | Tokens proxy |
| --- | --- | --- | --- | --- |
| tecnología | OK | 0.667 | 40.866 | 515 |
| error histórico | OK | 0.667 | 39.036 | 551 |
| módulo responsable | OK | 0.333 | 40.27 | 725 |
| rendimiento | OK | 0.667 | 40.916 | 630 |
| contexto para otra IA | OK | — | 41.829 | 1175 |
| contradicciones y obsolescencia | OK | — | 1.26 | — |

Se exige fuente relevante en primera posición para las cuatro consultas de recuperación. La precisión de fragmentos adicionales se publica sin ocultar resultados menos pertinentes. Las fuentes esperadas están declaradas en el evaluador; es un benchmark pequeño del entorno IA, no del producto.

Contradicciones/obsolescencia: fixture explícito con dos Claims incompatibles y registro obsoleto; se comprueba detección, exclusión de búsqueda y corrección. El linter no infiere contradicciones semánticas generales.

Lint memoria canónica: 0 problemas. Respaldos SHA256 verificados: True.

Fixture integral de herramientas/Git: True; commit de prueba d1d9dda406bb436b9b74422ca9dae054741ce380, rama ai/evaluation y estado limpio en repositorio temporal. Ese fixture se retira al terminar; no es el commit de entrega ni llama a un modelo.

Delegación real y consulta pública: [DELEGATION_PROBE.md](DELEGATION_PROBE.md). Las pruebas unitarias de aislamiento usan dobles; proveedor y ejecución nocturna reales siguen sin certificarse. Estado final de pruebas y prerrequisitos: [FINAL_REPORT.md](FINAL_REPORT.md).

Tokens proxy = ceil(caracteres/4), aproximación de tamaño de contexto, no tokenizer ni coste real. Tokens facturados, llamadas del modelo y coste de esta sesión no se exponen: null. No hay suscripciones añadidas ni embeddings instalados.
