# Registro seguro

`SafeLogger` publica registros estructurados a sinks inyectados; `MemoryLogSink` sirve para pruebas. El logger sanea campos sensibles y no configura persistencia ni escribe por sí mismo en archivos.

| Archivo | Responsabilidad | Pruebas |
|---|---|---|
| `safe_logger.dart` | Niveles, registros, sinks, saneamiento y cierre | No hay suite unitaria exclusiva identificada; se valida indirectamente desde módulos consumidores. |

Depende solo de Dart y de `core/errors`. Para añadir campos, ampliar el saneamiento y verificar que tokens, cabeceras y parámetros privados no aparezcan. No incorporar filesystem o logger de plataforma sin un adaptador separado.
