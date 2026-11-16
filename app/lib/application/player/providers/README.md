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

## Circuit breaker y caché

El descubrimiento tiene un breaker por `providerId`; la resolución comparte un
breaker por hostname de destino entre adapters. Ambos usan 3 fallos transitorios
consecutivos y 60 s de enfriamiento, reloj inyectable y un único probe
half-open. Cada host se cuenta como una unidad durante una búsqueda completa:
se prueban sus alternativas finitas y un éxito posterior sana el host; una
fallida no bloquea otros hostnames. Cancelación y fallos no transitorios no
consumen el umbral. `diagnostics` y `hostDiagnostics` exponen estados separados.
El registro de breakers de host es LRU y no conserva más de 128 destinos; evita
crecimiento por catálogos variables. Si está lleno únicamente con circuitos
abiertos o probes activos, un host nuevo se omite con `circuitOpen` hasta que
haya una entrada evictable. La expulsión de un circuito cerrado/ya vencido
descarta su historial de fallos.

El registro acepta versión SemVer y TTL por provider. El `PlaybackSourceCache`
mantiene hasta 128 entradas LRU en memoria, con TTL por defecto de 30 s,
máximo 5 min y expiración efectiva acortada al primer candidate que expire.
TTL cero lo desactiva. No se cachean errores ni resultados vacíos; la caché no
es persistente.

## Dependencias, pruebas y extensión

El módulo depende solo de contratos/models del dominio. La capa app puede pedir
`findSources` para mostrar alternativas o `resolveBestStream` para obtener una
URI; otra capa coordina esa URI con el player. Al registrar un proveedor,
declarar capacidades, prioridad y activar las contract tests compartidas.

```bash
flutter test --no-pub test/application/playback_provider_manager_test.dart
```

Los tests cubren orden, empty/error fallback, servidor caído, circuitos
compartidos por hostname, registro host LRU acotado a 128 entradas, recuperación
half-open ante respuestas transitorias y no transitorias, 60 s sin sleeps,
probe único, aislamiento, deduplicación pública/interna, cancelación por
llamador y respuesta inválida.

La limpieza S0-S retiró también AnimeHeaven: los tres mirrors live fallaron en
libmpv, y su protocolo de gate y resolver estaban acoplados al sitio. El
composition root registra AnimesDigital únicamente como candidato; no hay
fuente marcada `verified_video`. Las guías anteriores quedaron en el
[archivo S0](../../../../../docs/ai-system/archive/providers/S0-2026-11-16/README.md).

El dominio incluye `EpisodeSourceAdapter` con búsqueda, enumeración de
episodios y descubrimiento de fuentes separados; su bridge usa este manager y
rechaza matches fuzzy antes del playback. El composition root registra el
candidato AnimesDigital y únicamente `DirectMediaHostResolver` como resolver
concreto; no hay extractor específico de host activo. El HLS del episodio 1180
respondió por HTTP pero mostró error de decodificación en la ventana real; no
se declara funcional ninguna fuente de anime. Ver el
[baseline e implementación S0-S](../../../../../docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md),
el [informe de limpieza](../../../../../docs/ai-system/audits/S0-provider-cleanup-audit-2026-11-15.md)
y el [reporte S0](../../../../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).
