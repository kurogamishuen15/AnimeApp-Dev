# Rendimiento — fase posterior, NO ejecutada

Todas las métricas (RSS inicial/home/búsqueda/detalle/10 min de reproducción,
arranque frío, jank, tamaño APK por ABI, tamaño Linux profile) están **no medidas**.
No usar tiempos de flutter test o builds debug como perfil del producto.

Observaciones concretas para medir después de acreditar paridad:

| Área | Evidencia actual | Propuesta pendiente | Condición |
| --- | --- | --- | --- |
| Imágenes | main.dart:20-22 ya limita 120 / 48 MiB | medir RSS y decodificación de portadas al tamaño renderizado | conservar default, opción si cambia calidad/caché |
| Startup | main.dart:23-26 espera CatalogModule.open | medir primer frame, DB y creación de servicios | no mover inicialización necesaria sin test de orden |
| Parser | miruro_catalog_api.dart:160-190 XOR/gzip síncrono | medir tiempo CPU y payload antes de Isolate.run | resultados golden idénticos; sin cambiar parser |
| Player | existe lease y dispose en engine | medir un solo decoder, cierre, seek exacto y RSS | no sustituir coordinación/lifecycle existente |
| Probe | main.dart:103-124 isolate sin handle, Future sin await | separar corrección de lifecycle del refactor; luego medir apagado/minimizado | decisión funcional previa, no optimización silenciosa |
| Buffer | PlayerConfiguration.bufferSize existe en media_kit 1.2.6 | evaluar opción bajo consumo | mantener default y medir buffering/RSS |
| Listas | listas builder ya existen | revisar grids/episodios y cacheWidth por widget | geometría y comportamiento iguales |

No eliminar dependencias, pesos tipográficos, assets ni fuentes. No habilitar
modo bajo consumo automático hasta disponer de scaffolds y pruebas por plataforma.
Cada optimización requiere medida antes/después en profile y commit perf separado;
si no mejora o rompe paridad, revertir exclusivamente ese commit.
