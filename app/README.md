# AnimeApp — aplicación Linux

Esqueleto Flutter que se implementa y valida primero en Fedora/Linux. F1.4 organiza el código existente por responsabilidades; no incorpora funciones de catálogo, ajustes, reproducción, red ni persistencia.

## Estructura activa

```text
app/lib/
├── main.dart
├── app/
│   ├── README.md
│   └── anime_app.dart
└── domain/
    ├── README.md
    └── app_identity.dart
```

`app/lib/app/` compone y presenta la aplicación. `app/lib/domain/` mantiene identidad Dart pura. `main.dart` es el único punto de entrada. No se crearon `core`, `shared`, `features`, `integrations` o `platform`: no hay consumidores/implementaciones que justifiquen esos directorios todavía. El runner actual vive en `app/linux/`.

## Límites de dependencias

- Dominio puede usar Dart puro y otros contratos de dominio; no puede importar Flutter/UI, composición `app`, infraestructura, integraciones ni APIs de sistema.
- Presentación depende de Flutter y consume dominio/casos de uso. No accede directamente a almacenamiento, red, autenticación o motor multimedia.
- Adaptadores e integraciones se añadirán solo en sus fases y cuando exista una necesidad concreta. No hay adaptadores anticipados para Android, Android TV o Windows.
- Dependencias de producto actuales: solo Flutter SDK; no se añadieron paquetes.

El checker recursivo protege cualquier carpeta llamada `domain` bajo `lib`, resuelve imports `package:` del paquete y relativos, y prohíbe dependencias de dominio a composición, presentación, infraestructura e integraciones de plataforma. Sus fixtures y limitaciones están en [`scripts/README.md`](../scripts/README.md).

## Comprobaciones

Desde `app/`:

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test --no-pub
flutter run -d linux --no-pub
```

Desde la raíz del repositorio:

```bash
dart scripts/check_imports.dart --root .
bash scripts/test_check_imports.sh
bash scripts/ci.sh
```

F0.4–F0.6 y el fallo conocido de `flutter analyze` se registran en [`PROGRESS.md`](../PROGRESS.md) y [`TESTING.md`](../TESTING.md). Los resultados de esta ejecución de F1.4 se anotan allí y en la sesión vinculada; no se considera exitoso un comando solo porque aparezca en esta lista.

## Rendimiento y ciclo de vida

El arranque no crea servicios, procesos o tareas en segundo plano. Cada módulo debe cerrar recursos que cree y justificar cachés o inicialización costosa. El checker y los README no añaden dependencias de runtime.

## Portabilidad y próximos módulos

La composición Flutter y la identidad Dart son reutilizables; el runner y el empaquetado actuales son Linux. Cuando haya una función, se añadirá su módulo dentro de `features/` o `integrations/` según responsabilidad. Los tipos transversales irán a `core/` solo al tener varios consumidores; `shared/` exige reutilización real. `platform/` se reservará para adaptadores concretos. La inclusión futura de Android/TV/Windows requiere análisis de dependencias, adaptación de UI/host y pruebas de paridad; no se preparan ahora archivos vacíos.

F1.5 definirá el catálogo de ajustes y sus tipos/defaults. F1.6 implementará la persistencia local aprobada. Ninguna de las dos subfases forma parte de este esqueleto.
