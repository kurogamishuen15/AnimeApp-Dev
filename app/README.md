# AnimeApp — aplicación Linux

Aplicación Flutter con ejecución inicial Fedora/Linux y lógica de dominio Dart
reutilizable. La UI incluye un recorrido local de demostración: búsqueda con
fixtures sintéticos, detalles, biblioteca, estado provisional y progreso
persistido en SQLite. No requiere cuenta ni servicios externos. Los contratos
AniList, secure storage y sync permanecen separados y no se activan en ese
recorrido.

## Estructura activa

```text
app/lib/
├── app/                 composición y UI Flutter del catálogo local
├── application/         orquestación Dart del catálogo
├── core/                Result, errores y logging seguro
├── data/                SQLite, fake metadata, AniList y secure storage
├── domain/              modelos y puertos Dart puros
├── settings/            registro y store de preferencias
├── main.dart            punto de entrada Linux/Flutter de producto
└── main_player_spike.dart entrypoint aislado opt-in para F2.2
```

Cada módulo documenta responsabilidades, pruebas y portabilidad en su README.
El flujo local reutiliza biblioteca/progreso existentes y sobrevive cierre y
reapertura. No conecta ajustes, autenticación, sync ni reproducción al catálogo.
Android, Android TV y Windows no forman parte de esta implementación.

F2.2 añade un spike opt-in independiente para video local con `media_kit`/libmpv,
coordinador y UI propios. Solo se ejecuta seleccionando
`lib/main_player_spike.dart`; no reemplaza el entrypoint de producto ni conecta
reproducción al catálogo, Drift o progreso. El detalle técnico está en el
[informe F2.2 v2](../docs/player/F2.2-spike-report-v2.md).

## Límites de dependencias

- El dominio usa Dart puro y contratos del dominio; no importa Flutter/UI,
  composición, plugins, red ni base de datos.
- UI y composición llaman a capacidades a través de `CatalogService` y puertos;
  no usan SQL ni HTTP directamente.
- `FakeMetadataProvider` solo sirve datos sintéticos y no representa una fuente
  real autorizada.
- Adaptadores multiplataforma futuros solo se incorporan cuando exista un
  consumidor y una necesidad validada.
- El adaptador de reproducción existe solo como spike aislado F2.2. Su contrato
  temporal no reemplaza `PlaybackEngine` previsto para F2.5.

El checker recursivo protege cualquier carpeta `domain` bajo `lib`, resuelve
imports package/relativos y aplica límites de arquitectura. Sus fixtures están
en [`scripts/README.md`](../scripts/README.md).

## Comprobaciones

Desde `app/`, con el SDK seleccionado según [`TESTING.md`](../TESTING.md):

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build linux --release --no-pub
```

Desde la raíz del repositorio:

```bash
dart scripts/check_imports.dart --root .
bash scripts/test_check_imports.sh
bash scripts/ci.sh
```

La suite integrada usa SQLite en archivos temporales y servidores loopback. El
test de catálogo bloquea HTTP, recorre UI y reinicia la composición conservando
biblioteca/progreso. No usa cuentas/keyring del usuario ni llama a AniList,
TMDB o Kitsu. Resultados y límites están en la [sesión de integración local](../docs/memory/sessions/2026-11-09-catalog-local-integration.md)
y la [auditoría previa F1.5–F1.12](../docs/validation/2026-11-09-f1-5-f1-12-real-tests.md).

## Herramientas y distribución

La stable Flutter local aún tiene el fallo LSP de Unicode documentado en
[`TESTING.md`](../TESTING.md). La validación reproducible usó el SDK beta
aislado de `.ai-local/toolchains/flutter`; no se cambió el SDK global. La
compilación Linux comprueba el destino de desarrollo, no el empaquetado Flatpak
ni rendimiento en hardware de 4 GB.

La composición Flutter y los contratos Dart son reutilizables. Linux es la
única plataforma ejecutable validada aquí. Los estados de biblioteca y el
episodio `episode:1` de la demo son provisionales, no decisiones de producto.
El backend de keyring requiere prueba runtime autorizada; elegibilidad de
AniList e integración de cuentas siguen pendientes.

## Inicio

La aplicación abre [Inicio de Kongroo](lib/app/home/README.md), con datos de muestra y lectura del progreso local. El shell conserva los accesos a Catálogo y Mi biblioteca.
