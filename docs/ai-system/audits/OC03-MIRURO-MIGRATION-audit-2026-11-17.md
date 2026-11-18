Fuente: orden directa del propietario y material Anilili proporcionado
Fecha: 2026-11-17
Módulo: Kongroo · proveedores y reproducción
Estado: PARCIAL · implementación integrada; reproducción externa bloqueada
Decisión: adaptar el catálogo Miruro al contrato existente; conservar manager y player
Evidencia: tests Flutter, análisis, build Linux, captura local y auditorías live enlazadas

# Auditoría OC-03: sustitución de providers experimentales por Miruro

## Resultado

Se retiraron del runtime los adaptadores de proveedores y perfiles de host
experimentales. Se adaptó el flujo del catálogo Miruro documentado por Anilili
a los contratos y al manager existentes. No se creó otro registry, coordinador,
resolutor de embeds ni reproductor.

El provider nuevo está integrado y tiene cobertura offline. No está validado
operativamente: la evidencia live previa de configuración y lookup Miruro para
AniList 100240 documenta HTTP 403 en dos orígenes antes de la lista de episodios
y de media. No se repitió esa solicitud en este cierre, ni se portó la emulación
de Chrome/challenge de Anilili. Resultado: **0 servidores de anime con
reproducción externa confirmada**. S0 permanece parcial.

## Alcance de la revisión y preservación

La raíz Git fue verificada como `/home/kyouma/Vídeos/PROYECTO ANIME`. El
checkout ya contenía cambios locales de OC-02/OC-03 en Home, AniList, progreso,
manager, coordinator y engine antes de la revisión. Se conservaron. La
implementación de esta migración no revirtió ni reescribió esos archivos. No se
preparó índice, commit, push ni remoto.

Se comprobaron referencias de runtime y pruebas a los adapters antiguos. No
quedan imports ni registros Dart activos de AnimeAV1, TioAnime, AnimeGG,
AnimeHeaven, AnimeOnline Ninja, AnimesDigital, MP4Upload o YourUpload. Sus
informes y los READMEs archivados permanecen como referencias históricas. El
índice del archivo aclara que esos documentos no representan código activo.

Archivos eliminados por la limpieza AnimesDigital de esta misión:

- `app/lib/data/player/providers/animesdigital/README.md`
- `app/lib/data/player/providers/animesdigital/animesdigital_html_parser.dart`
- `app/lib/data/player/providers/animesdigital/animesdigital_playback_provider.dart`
- `app/test/data/player/providers/animesdigital/animesdigital_html_parser_test.dart`
- `app/test/data/player/providers/animesdigital/animesdigital_playback_provider_test.dart`
- `app/test/tool/animesdigital_live_harness_test.dart`
- `app/tool/animesdigital_live_harness.dart`
- `app/tool/animesdigital_live_player_app.dart`

Se retiraron tests/harness cuyo código objeto ya no existe. Se conservaron
`PlaybackProviderManager`, `PlaybackSourceSwitchService`, los contratos de
fuentes/episodios, los circuit breakers y `media_kit/libmpv`. El estado de Git
ya contenía cambios concurrentes en parte de esos componentes; esta auditoría
no atribuye esos cambios previos a la migración.

## Flujo integrado

`MiruroCatalogPlaybackProvider` implementa `EpisodeSourceAdapter` v1.0.0. Usa
AniList ID exacto para identificar el título y el endpoint `play` directo para
el episodio seleccionado por la ficha. Mantiene `listEpisodes` para el flujo de
enumeración completa con cursor. `MiruroCatalogParser` ordena providers a
partir del catálogo, conserva idiomas declarados y metadata, agrupa variantes
de calidad del mismo servidor y excluye embeds. Los medios que llegan al
manager son HTTPS directos de formato conocido.

`PublicPlaybackHttp` aplica timeout, cancelación, límites de concurrencia y
bytes. La respuesta por defecto queda limitada a 2 MiB y el máximo configurable
es 8 MiB; la salida descomprimida XOR+gzip también está limitada a 8 MiB. Los
GET usan orígenes exactos, no siguen redirects y no transportan cookies,
Authorization ni UA de navegador. La API solo prueba otros orígenes en errores
de red o 5xx; 4xx, challenges y rate limits no se repiten. Las cachés internas
del provider tienen TTL y tamaño acotados.

El manager entrega los candidatos al único `DirectMediaHostResolver`, que
normaliza URL, formato, cabeceras públicas permitidas y disponibilidad. Este
resolver no hace HEAD/GET ni certifica disponibilidad. El único engine sigue
siendo `SpikePlayerModule` → `MediaKitSpikeEngine` → `media_kit/libmpv`.

El módulo registra Miruro por defecto, y permite desactivarlo mediante
`KONGROO_ENABLE_MIRURO=0`; Wikimedia requiere `KONGROO_ENABLE_WIKIMEDIA=1` y las
fuentes definidas por el usuario siguen siendo opcionales. Se reutiliza Dio ya
presente. No se cambió `pubspec.yaml` ni `pubspec.lock` por esta integración.

## Revisión de licencia y límites de protocolo

La implementación del catálogo se inspiró en los endpoints y modelos del ZIP
Anilili proporcionado. Se escribió en Dart para los contratos actuales; no se
copió código Kotlin, Runtime Android, WebView, Cloudflare interceptor, cookies,
cliente navegador ni resolutor Anivexa/AniChan. Se conserva el aviso MIT-0 y la
procedencia en [`docs/third-party/ANILILI-MIT-0.md`](../../third-party/ANILILI-MIT-0.md).

El parser XOR+gzip solo decodifica el formato de payload del catálogo y no es un
método de acceso a contenido protegido. No se implementan DRM, login, CAPTCHA,
challenge, extracción JavaScript o transformación de segmentos.

## Pruebas, build y observación gráfica

SDK local aislado: Flutter `3.50.0-0.4.pre`, Dart `3.14.0`. No se modificó el
SDK global. Con el SDK Flutter 3.47.9 el análisis del proyecto continúa
afectado por el fallo LSP conocido de `SemanticsRole.slider`; ese intento falló
antes de evaluar el código actual y no se cuenta como análisis aprobado.

- Flutter focalizado para providers, contracts, resolver y manager: **62/62**.
- Suite Flutter completa en serie: **334 aprobadas, 10 optativas omitidas**.
- `flutter analyze --no-pub`: sin issues.
- `flutter build linux --debug --no-pub`: build completado.
- La captura Wayland confirma que Home abrió y rasterizó el primer frame:
  `.ai-local/review/oc03-home.png` (archivo ignorado/local). El backend Wayland
  no ofreció teclado ni puntero utilizables; no se hizo una revisión manual de
  controles, ficha o navegación por servidor.
- Ningún test fake se presenta como prueba live. El playback Miruro permanece
  bloqueado por la denegación upstream documentada en
  [`OC03-ANILILI-BEE-audit-2026-11-17.md`](OC03-ANILILI-BEE-audit-2026-11-17.md).

La suite completa ejecutó una regresión del engine sobre archivos locales con
20 aperturas: RSS informado por el test fue 251,928,576 B antes, 396,959,744 B
pico después de Stop y 377,868,288 B después de dispose. No es una medición de
la app en reposo, de un provider remoto, del equipo de 4 GB ni una prueba soak;
no permite declarar ausencia o presencia de una fuga. La fuente externa no
abrió, por lo que su RAM/CPU/consumo de red durante streaming no se pudieron
medir.

## Auditoría de riesgos y estado

| Nivel | Hallazgo | Estado |
|---|---|---|
| P1 | Miruro devuelve 403 antes de episodios/media; criterio de reproducción real incumplido y 0 servers de anime confirmados | Abierto; requiere acceso público permitido o un host/provider alterno con ruta ordinaria verificable |
| P2 | Android y Windows no tienen build ni runtime probados; contratos son Dart y las dependencias de datos no añaden una API Linux exclusiva | Abierto; compatibilidad arquitectónica preparada, ejecución no acreditada |
| P2 | No hubo video Miruro disponible para medir rendimiento de stream; host objetivo de 4 GB no estuvo disponible | Abierto; medir cuando exista un stream accesible en ese equipo |
| P2 | Falta interacción manual Wayland de ficha → episodio → selector → player → retorno; solo se observó Home | Abierto; captura confirma ventana y primer frame, no navegación |

Corrección encontrada en revisión: `PublicPlaybackHttp` comparaba la respuesta
contra 2 MiB aunque una llamada solicitara un límite mayor. Se ajustó a
`maxResponseBytes` y se añadió un test loopback de respuesta de 3 MiB con límite
4 MiB; el test pasa. La descompresión mantiene su cota independiente.

**Conclusión:** la estructura de código ya usa el flujo Miruro desde la ficha,
pero no puede cumplir reproducción real mientras el catálogo deniegue el GET
ordinario. No cerrar misión ni declarar servidores funcionales. No hay hallazgo
P0 en este alcance; queda abierto el gate P1 funcional y los P2 anteriores.
