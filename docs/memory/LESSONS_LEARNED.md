# Lecciones verificables

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-001, AI-002
Evidencia: Auditoría y sesiones documentadas

## Error histórico y corrección
Se confundió la carpeta vacía de coordinación con la ubicación del código y se localizó otro repositorio. El usuario restringió el alcance a esta carpeta de Vídeos. No se modificó el otro repositorio. Corrección: prohibir accesos posteriores, construir infraestructura aquí y registrar como desconocidos los detalles del producto. Ver [episodio inicial](sessions/2026-11-07-setup.md).

## Permisos y verificación
Un directorio .git visible no garantiza un repositorio funcional. Un TOML válido no garantiza que el runtime cargue sus claves; contrastar ayudas, esquema estricto y evidencia de agentes disponibles.

## Recursos
Limitar la salida final no limita la RAM antes de generarla. La auditoría pidió límites de lectura, captura y archivos escribibles, además del presupuesto de contexto.
