# Coordinación de proveedores de reproducción F2.5

## Propósito y límites

`PlaybackProviderManager` registra proveedores inyectados, impone una prioridad
determinista, valida resultados, intenta alternativas acotadas, elimina
consultas duplicadas en vuelo y publica diagnóstico por proveedor. No crea ni
controla `Player`, no importa Flutter/media_kit, y no conecta proveedores
reales en F2.5.

## Archivos

| Archivo | Responsabilidad | Dependencias |
|---|---|---|
| `playback_provider_manager.dart` | registry inmutable, deduplicación, validación, orden, fallback y resolución | contratos/modelos de dominio |
| `provider_circuit_breaker.dart` | circuito con reloj inyectado, permit y probe único | Dart y tipos de fallo del dominio |
| `README.md` | política, ciclos, pruebas y extensión | módulos vecinos |

## Política de orden y fallback

Las registraciones enabled se ordenan por prioridad descendente y luego por
provider ID ascendente. Fuentes y servidores usan la misma regla de prioridad
descendente y empate por ID. `findSources` continúa ante resultado vacío,
capacidad ausente, respuesta inválida o fallo elegible; devuelve la primera
lista válida no vacía. `resolveBestStream` prueba cada servidor de cada fuente
ordenada y luego pasa al proveedor siguiente. Cada alternativa se visita como
máximo una vez por petición; el límite efectivo es la cantidad finita de
fuentes/servidores devuelta por los proveedores. El último fallo tipado no se
oculta.

El manager valida IDs de proveedor, unicidad de fuente, episodio solicitado,
capacidades declaradas y consistencia de provider/source/server en el stream
resuelto. DTOs malformados cuentan como `invalidResponse` y no incrementan el
breaker ordinario. Las excepciones inesperadas del adaptador se convierten en
`unavailable` sin exponer mensajes o datos arbitrarios.

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
inyectable y un único probe half-open. Un resultado exitoso reinicia el contador;
un probe fallido vuelve a abrir 60 s; una cancelación libera el probe sin
contar. Error de cuota sí cuenta; respuesta inválida, autorización, capacidad
no soportada y cancelación no cuentan en estado cerrado.

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

Los tests cubren orden, empty/error fallback, servidor caído, circuitos de
descubrimiento/resolución, 60 s sin sleeps, probe único, aislamiento,
deduplicación pública/interna, cancelación por llamador y respuesta inválida.

AnimeAV1 y TioAnime implementan el puerto en la composición actual. Su
presencia no implica que el stream sea reproducible: el estado live y la prueba
con libmpv están en [`data/player/providers`](../../../data/player/providers/README.md).
