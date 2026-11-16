# Coordinación de proveedores de reproducción F2.5

## Propósito y límites

`PlaybackProviderManager` registra adaptadores de anime y resolutores de host
por separado. Ordena ambas listas de forma determinista, valida resultados,
intenta alternativas acotadas, elimina consultas duplicadas en vuelo y publica
diagnóstico por proveedor. No crea ni controla `Player` ni importa Flutter o
media_kit.

## Archivos

| Archivo | Responsabilidad | Dependencias |
|---|---|---|
| `playback_provider_manager.dart` | registry inmutable, deduplicación, validación, orden, fallback y resolución | contratos/modelos de dominio |
| `provider_circuit_breaker.dart` | circuito con reloj inyectado, permit y probe único | Dart y tipos de fallo del dominio |
| `PlaybackVideoHostResolverRegistration` | resolver de host registrado por separado del proveedor de anime | contrato `PlaybackVideoHostResolver` |
| `README.md` | política, ciclos, pruebas y extensión | módulos vecinos |

## Política de orden y fallback

Los proveedores enabled se ordenan por prioridad descendente y luego por
provider ID ascendente; los resolutores de host por `resolverId` y prioridad.
Fuentes y servidores usan prioridad descendente y empate por ID. `findSources` continúa ante resultado vacío,
capacidad ausente, respuesta inválida o fallo elegible; devuelve la primera
lista válida no vacía. `resolveBestStream` prueba cada servidor de cada fuente
ordenada y luego pasa al proveedor siguiente. Cada alternativa se visita como
máximo una vez por petición; el límite efectivo es la cantidad finita de
fuentes/servidores devuelta por los proveedores. El último fallo tipado no se
oculta.

Los proveedores de anime solo implementan descubrimiento. Para cada servidor,
el manager elige el primer `PlaybackVideoHostResolver` registrado que declare
soporte. Valida IDs de proveedor, unicidad de fuente, episodio solicitado,
capacidades declaradas y consistencia de provider/source/server en el stream
resuelto. DTOs malformados cuentan como `invalidResponse` y no incrementan el
breaker ordinario. Las excepciones inesperadas se convierten en `unavailable`
sin exponer mensajes ni datos arbitrarios.

Las llamadas `findSources` idénticas comparten la misma operación del
proveedor, incluso cuando una consulta pública coincide con una resolución en
curso. Cada llamador conserva una cancelación independiente de su espera. La
operación cooperativa compartida solo se cancela cuando todos los llamadores
activos se retiran; una cancelación tardía no revierte una respuesta ya
completada. Las entradas en vuelo se eliminan al completar y no se cachean
respuestas.

## Circuit breaker

Cada proveedor mantiene dos breakers independientes: descubrimiento de fuentes
y resolución de servidor. Esas son unidades de fallo distintas: una API puede
seguir ofreciendo fuentes mientras un servidor/stream está caído, o viceversa.
Ambos usan política 3 fallos elegibles consecutivos → 60 s abiertos, reloj
inyectable y un único probe half-open. En resolución, la unidad es una operación
completa por proveedor, no cada servidor individual: el manager prueba todas
las alternativas antes de registrar un fallo agregado, y cualquier servidor
resuelto reinicia el contador. Así, tres espejos fallidos no impiden probar el
cuarto dentro de la misma selección. Un probe fallido vuelve a abrir 60 s; una
cancelación libera el probe sin contar. Error de cuota sí cuenta; respuesta
inválida, autorización, capacidad no soportada y cancelación no cuentan en
estado cerrado.

`diagnostics` expone estado, fallos, vencimiento y último error por separado
para descubrimiento y resolución. Un proveedor abierto no bloquea proveedores
sanos. Circuitos abiertos no repiten llamadas al endpoint afectado.

## Dependencias, pruebas y extensión

El módulo depende solo de contratos/models del dominio. La capa app puede pedir
`findSources` para mostrar alternativas o `resolveBestStream` para obtener una
URI; otra capa coordina esa URI con el player. Al registrar un proveedor,
declarar capacidades, prioridad y activar las contract tests compartidas.

```bash
flutter test --no-pub test/application/playback_provider_manager_test.dart
```

Los tests cubren orden, empty/error fallback, servidor caído, tres alternativas
fallidas seguidas de un servidor sano, circuitos de descubrimiento/resolución,
60 s sin sleeps, probe único, aislamiento, deduplicación pública/interna,
cancelación por llamador y respuesta inválida.

Los adaptadores AnimeAV1, TioAnime y AnimeGG y el resolver HTTP estático fueron
retirados en la limpieza S0 porque no produjeron video externo verificado.
AnimeHeaven es la primera integración posterior: busca títulos y episodios y
valida mirrors MP4, pero el smoke visual de libmpv todavía no confirmó imagen.
Los contratos de provider/resolver, prioridades, alternativas, fallbacks y el
paso seguro al player permanecen compartidos. Ver el [informe de limpieza](../../../../../docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md)
y el [reporte S0](../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).
