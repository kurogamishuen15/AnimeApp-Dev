# Resultados por carpetas

Comandos con --timeout 15s y límite externo 90s por carpeta, concurrencia 1.
Los fallos de carga son archivos no ejecutados, no aserciones fallidas.

| Carpeta | Pasan observados | Fallos observados | Omitidos | Exit | Límite |
| --- | --- | --- | --- | --- | --- |
| core | 7 | 0 | 0 | 0 | terminó; fallos incluyen carga/compilación |
| data | 121 | 9 | 4 | 1 | terminó; fallos incluyen carga/compilación |
| settings | 6 | 0 | 0 | 0 | terminó; fallos incluyen carga/compilación |
| domain | 32 | 0 | 0 | 0 | terminó; fallos incluyen carga/compilación |
| player | 35 | 8 | 4 | 124 | interrumpida; conteos parciales |
| application | 6 | 1 | 0 | 1 | terminó; fallos incluyen carga/compilación |
| home | 26 | 0 | 0 | 0 | terminó; fallos incluyen carga/compilación |
| catalog | 4 | 0 | 0 | 0 | terminó; fallos incluyen carga/compilación |

Widget raíz: +0 -1, fallo de carga por manager. `test/tool` es directorio vacío;
Flutter lanzó la suite completa como fallback. Esa corrida acabó con timeout y
NO se suma a los totales (duplicaría pruebas). Se conservó el log por trazabilidad;
el runner ya excluye carpetas vacías. No se reintentó el fallback.
La suite previa completa también tuvo timeout. No se afirma un total global verde.
Los golden nuevos se verifican aparte en logs/golden_all.txt; no sumarlos a los
conteos históricos de carpeta data cuando se añadieron posteriormente.
