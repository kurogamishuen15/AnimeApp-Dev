# Archivo de pruebas fuente S0-A — Miruro

**Estado:** evidencia histórica; las copias de este directorio no son tests
ejecutables y no forman parte de `app/test/`.

El 2026-11-15 se conservaron aquí, byte por byte, los tests específicos del
intento S0-A de Miruro y la prueba de composición anterior a la limpieza. Se
guardan con extensión `.dart.txt` para mantener la evidencia sin permitir que
Flutter los descubra como tests activos. También se archivó la versión que
existía en `HEAD` de `public_playback_provider_test.dart`, retirada durante la
limpieza S0 anterior.

Los fixtures que contienen `token=fixture`, `sig=fixture` o
`fixture-cookie` son marcadores sintéticos de test; no son URLs firmadas,
credenciales ni capturas de tráfico real. Los resultados medidos y los límites
de las pruebas constan en el [informe S0-A](../../missions/S0-ANILILI-PORT-REPORT.md),
su [auditoría](../../audits/S0-ANILILI-port-audit-2026-11-15.md) y la
[auditoría de limpieza posterior](../../audits/S0-provider-cleanup-followup-audit-2026-11-15.md).

No se archivó la implementación de Miruro. Sus archivos de runtime fueron
retirados porque el GET público respondió HTTP 403 y el flujo no obtuvo episodio
ni media reproducible. Esta carpeta no autoriza restaurar ni reutilizar ese
código; una integración nueva debe seguir una instrucción posterior y aportar
sus propias pruebas.
