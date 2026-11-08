# AI-002 — Aislamiento y recursos

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: autonomía
Estado: vigente
Decisión: AI-002
Evidencia: Auditoría de RAM y pruebas de rechazo seguro

Tipo: decisión
Claim: agents.concurrent_specialists = 1

## Decisión
Usar un especialista simultáneo en sesiones nuevas y ejecutar pruebas/indexación sin procesos residentes. El entorno mostró solo unos 1.9 GiB disponibles y swap en uso. No usar la RAM total como si estuviera libre.

## Modo nocturno
Preferir Podman rootless, imagen local inmutable, copia acotada, archivos escribibles explícitos, validación aislada, plazo y reportes. No usar permisos irrestrictos ni montar hogar, credenciales o socket del contenedor. Ausencia de imagen/proveedor es un bloqueo, no una aprobación implícita.

## Límites de rendimiento
Límites del corpus, salida y archivos se implementan en herramientas; CPU/RAM del contenedor se acotan. No hay objetivos de arranque/RAM de la aplicación verificables aquí. Una compilación Flutter en 4 GB requiere medición específica y ejecución secuencial.
