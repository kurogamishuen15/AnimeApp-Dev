# AnimeApp — aplicación Linux

Aplicación Flutter con ejecución inicial Fedora/Linux y lógica de dominio Dart
reutilizable. El núcleo ya incluye Result/errores/logger, contratos de dominio,
ajustes tipados, almacenamiento local SQLite, adaptadores AniList y secure
storage, además de repositorios locales de progreso y un contrato de sync.
Estos módulos no implican que los recorridos de producto estén conectados a la
interfaz.

## Estructura activa

```text
app/lib/
├── app/                 composición y UI inicial
├── core/                Result, errores y logging seguro
├── data/                SQLite, AniList y almacenamiento seguro
├── domain/              modelos y puertos Dart puros
├── settings/            registro y store de preferencias
└── main.dart            punto de entrada Linux/Flutter
```

Cada módulo documenta responsabilidades, pruebas y portabilidad en su README.
La composición visible aún presenta una pantalla inicial; no conecta ajustes,
catálogo, progreso, autenticación ni sincronización al flujo de producto.
Android, Android TV y Windows no forman parte de esta implementación.

## Límites de dependencias

- El dominio usa Dart puro y contratos del dominio; no importa Flutter/UI,
  composición, plugins, red ni base de datos.
- UI y composición llaman a capacidades a través de puertos y adaptadores; la
  integración del producto sigue pendiente.
- Adaptadores multiplataforma futuros solo se incorporan cuando exista un
  consumidor y una necesidad validada.
- No hay motor de reproducción implementado.

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

La suite integrada de F1.12 usa archivo SQLite real y servidores loopback. No
usa las cuentas/keyring del usuario ni llama a AniList externo. Los resultados
exactos y limitaciones están en [`docs/validation`](../docs/validation/2026-11-09-f1-5-f1-12-real-tests.md).

## Herramientas y distribución

La stable Flutter local aún tiene el fallo LSP de Unicode documentado en
[`TESTING.md`](../TESTING.md). La validación reproducible usó el SDK beta
aislado de `.ai-local/toolchains/flutter`; no se cambió el SDK global. La
compilación Linux comprueba el destino de desarrollo, no el empaquetado Flatpak
ni rendimiento en hardware de 4 GB.

La composición Flutter y los contratos Dart son reutilizables. Linux es la
única plataforma ejecutable validada aquí; el backend de keyring requiere
prueba runtime autorizada. La elegibilidad de AniList y la integración de
cuentas siguen pendientes.
