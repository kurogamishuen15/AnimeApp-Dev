# Adaptadores de proveedores

Los adaptadores implementan el contrato neutral `domain/player/providers/PlaybackSourceProvider`. No son motores: producen fuentes/servidores tipados y dejan que application coordine la selección.

| Submódulo | Responsabilidad | Estado y documentación |
|---|---|---|
| `playback_providers_module.dart` | Composition root Dio + `PlaybackProviderManager` con prioridades | AnimeAV1 (30), TioAnime (20); ninguno ha demostrado reproducción real |
| `animeav1/` | Catálogo público, episodios, servidor y resolución directa HTTPS | Catálogo/episodios reales; iframe devuelve 403. [`README.md`](animeav1/README.md) |
| `tioanime/` | Búsqueda exacta, lista pública de episodios y extracción de URL directa expuesta por embed | Episodios/servidores reales; libmpv no reprodujo los streams probados. [`README.md`](tioanime/README.md) |
| `animeonline_ninja/` | Registro del bloqueo observado y criterios para reanudar | [`README.md`](animeonline_ninja/README.md) |
| JKAnime / AnimeJara | No registrados | JKAnime denegó una solicitud ordinaria con 403; rutas de AnimeJara no confirmadas. |
| `mock/` | Escenarios reproducibles de éxito, alternativas y fallos | [`README.md`](mock/README.md), `test/domain/playback_provider_contract_test.dart` y `test/application/playback_provider_manager_test.dart` |

Los adaptadores reales usan únicamente GETs HTTPS corrientes con respuestas limitadas y fallos tipados. No mantienen sesión/cookies, no ejecutan JavaScript del sitio, no resuelven CAPTCHA, no eluden desafíos ni abren `Player`. Un embed se ofrece a libmpv solo si el HTML público expone un `.m3u8` o `.mp4` directo; formatos no soportados se reportan, no se descifran. El flujo de UI está conectado al player existente, pero no se marca operativo hasta superar reproducción real de un episodio.

Para añadir proveedor, convertir DTOs en modelos domain dentro de data, declarar capacidades explícitamente, documentar hosts y límites en el README propio, registrar el proveedor mediante el módulo, y ejecutar los contract tests. No copiar payloads externos a domain ni invocar libmpv desde el adaptador.
