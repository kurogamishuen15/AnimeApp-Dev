# Dominio de proveedores de reproducción F2.5

## Propósito

Define identidad, modelos inmutables y contratos independientes de cualquier
API externa o motor. Un **proveedor** entrega fuentes; una **fuente** identifica
una alternativa para un episodio; un **servidor** es un endpoint elegido dentro
de una fuente; el **motor** reproduce el URI resuelto y no conoce proveedores.

## Archivos y contratos

| Archivo | Responsabilidad | Contrato principal |
|---|---|---|
| `playback_source.dart` | `PlaybackEpisode`, ID de proveedor, fuente, servidor y stream resuelto | modelos normalizados e inmutables |
| `playback_provider_contract.dart` | capacidades, resultados y fallos tipados, cancelación cooperativa y puerto | `PlaybackSourceProvider` |
| `README.md` | límites, dependencias, pruebas y extensión | documentación de módulo |

`PlaybackSourceProvider.findSources` recibe identidad local, un ID externo
opcional (AniList para el flujo actual), aliases de título acotados y número
de episodio, nunca DTOs JSON. Los títulos y el ID externo forman parte de
`requestKey` para no fusionar episodios de títulos distintos. Devuelve
`Success`, `Empty`, `Unsupported` o
`Failed`; la resolución del servidor devuelve el URI utilizable. El proveedor
no puede acceder al `Player` ni importar `media_kit`. El adaptador de datos es
responsable de traducir esquemas remotos a estos tipos y de validar respuesta.

`PlaybackSource` conserva provider ID y episodio solicitado para que la capa
application pueda rechazar identidad ajena, fuente duplicada o respuesta para
otro episodio. Los servidores y streams solo admiten `http`, `https` o `file`;
esta validación sintáctica no prueba disponibilidad ni confianza del contenido.

## Errores y cancelación

`PlaybackProviderFailureKind` distingue indisponibilidad/red, timeout, límite
de cuota, respuesta inválida, autorización, capacidad no soportada, cancelación
y circuito abierto. Solo `unavailable`, `network`, `timeout` y `rateLimited`
cuentan como fallo elegible ordinario del breaker. En half-open, un fallo de
probe (incluida respuesta inválida/no soportada) vuelve a abrir el circuito;
cancelación libera el probe sin contar y una respuesta vacía de descubrimiento
es un resultado correcto sin fuentes.

`PlaybackCancellationToken` es una señal cooperativa y permite registrar
callbacks de cancelación para transportar la señal a sockets Dio. El adaptador
debe comprobarla antes y después de operaciones suspendidas; no cancela por la
fuerza un Future o recurso que no exponga cancelación. Los callbacks se
desregistran al terminar cada request.

## Dependencias y extensión

El dominio solo depende de `AnimeId` y Dart. Una integración nueva implementa
`PlaybackSourceProvider` en `data/player/providers/<nombre>/`, convierte sus
DTOs a estos modelos y debe reutilizar la batería de contract tests. Añadir una
capacidad requiere documentar su semántica y probar el comportamiento del
manager ante proveedores que no la declaran.

## Pruebas

Desde `app/`:

```bash
flutter test --no-pub test/domain/playback_provider_contract_test.dart
```

La suite prueba identidad/capacidades, fuentes y servidores válidos, resultado
vacío, error, timeout tipado, respuesta malformada y cancelación.
