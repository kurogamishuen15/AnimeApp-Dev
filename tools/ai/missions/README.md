# Misiones del ejecutor

JSON con objective, allowed_paths exactos, context_paths, validation_commands como listas argv, timeout_seconds 1..3600 y max_attempts 1..3. El ejecutor realiza un solo intento. commit debe ser false. allowed_paths requiere archivos existentes, rastreados, sin secretos ni symlinks; no admite comodines.

smoke.json es una prueba inocua y bloqueada por defecto: no incluye imagen ni proveedor preparados. No usar sobre producto. Antes de run, leer RUNBOOK y verificar Git limpio, imagen inmutable y aislamiento/proveedor reales. No agregar credenciales a misiones.
