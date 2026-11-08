# Pruebas del entorno IA

`python3 -W error::ResourceWarning -m unittest discover -s tests/ai -v` ejecuta pruebas de memoria y autonomía. Usan directorios temporales; las pruebas de Git crean repositorios inocuos y commits locales con identidad de fixture. No tocan funcionalidades de producto ni remotos.

Las pruebas de Podman/Codex usan dobles explícitos para verificar rechazos y construcción de comandos. No prueban un proveedor real, autenticación ni supervivencia nocturna. Ver EVALUATION.md para distinguir tests, investigación remota y ejecución real.

Añadir pruebas cuando exista un riesgo de regresión verificable, especialmente límites, rutas, integración y errores. No agregar dependencias para reproducir la implementación línea por línea.
