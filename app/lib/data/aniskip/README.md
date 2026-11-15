# AniSkip

El adaptador traduce respuestas de [AniSkip v1](https://api.aniskip.com/api-docs) a rangos del dominio. Se compone con un ID MAL comprobado para el episodio. El identificador local de anime y el de AniList no se usan como sustituto.

| Archivo | Contrato |
|---|---|
| aniskip_client.dart | Lookup tipado por episodio y MAL. Mapea op y ed, descarta tipos ajenos y duplicados, y devuelve fallos de red, cuota, servidor, respuesta o almacenamiento |
| aniskip_response_cache.dart | Puerto de caché y almacenamiento local mediante path_provider. Guarda respuesta, versión, fecha de lectura y expiración. Los nombres de archivo derivan de versión, ID MAL y episodio |

El reloj, Dio y la ubicación de almacenamiento son inyectables. Por defecto el adaptador crea su cliente HTTP y lo libera con close. Las respuestas correctas, incluidas las vacías, expiran al cabo de siete días. Los errores de red no se persisten. El controlador de aplicación comprueba el episodio y la duración de la fuente antes de mostrar un botón o encolar un salto.

Ejecutar desde app con el SDK aislado:

    ../.ai-local/toolchains/flutter-3.47.9/bin/flutter test --no-pub test/data/aniskip/aniskip_client_test.dart

La suite utiliza respuestas de prueba. La conectividad pública, un resolver de mapeos MAL y el uso en el catálogo real quedan pendientes.
