# F1.4 — Estructura modular inicial

Fuente: autorización explícita del propietario y criterios F1.4 del plan de trabajo
Fecha: 2026-11-08
Módulo: aplicación Flutter y checker arquitectónico
Estado: completada; limitación conocida de `flutter analyze` preservada
Decisión: conservar app/domain mínimos, documentar módulos y proteger todos los dominios con checker recursivo
Evidencia: `app/README.md`, READMEs bajo `app/lib`, `scripts/check_imports.dart`, `scripts/test_check_imports.sh`, PROGRESS.md

## Situación anterior y estructura resultante

Antes de F1.4, `app/lib` contenía `main.dart`, `app/anime_app.dart` e `domain/app_identity.dart`; solo había `app/` y `domain/`, sin README de módulo ni ajustes. Se preservaron ubicaciones y comportamiento: mover `domain` solo para imitar un árbol sería un cambio sin beneficio.

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

No se crearon `core`, `shared`, `features`, `integrations` o `platform`, ya que no tienen hoy un consumidor/capacidad real. No se crearon adaptadores de sistemas futuros ni se modificó código funcional de la app.

## Cambios

- Se actualizó `app/README.md` con estructura real, límites, comandos de validación y evolución futura.
- Se documentaron `app/lib/app/` y `app/lib/domain/`, contratos actuales, dependencias, pruebas y portabilidad.
- Se amplió `scripts/check_imports.dart` para escanear recursivamente todos los archivos Dart bajo `app/lib` que estén dentro de cualquier carpeta `domain`, incluida una futura feature. Resuelve URIs package propias, relativas y file; rechaza Flutter/UI, `dart:io`/`dart:ffi`, composición, capas UI/infraestructura, plugins conocidos y rutas locales fuera de `app/lib`.
- Se amplió `scripts/test_check_imports.sh`: un caso permitido y diez casos de violación (Flutter, presentación, integración, Flutter en dominio de feature, evasión relativa, plugin de plataforma, archivo Dart enlazado, carpeta `domain` enlazada y raíces `app`/`app/lib` enlazadas), más la ejecución del checker sobre el proyecto real. Exit 1 de violación se comprueba explícitamente.
- Se actualizaron `scripts/README.md`, ROADMAP, PROGRESS, índices y este registro. No se editaron archivos de `docs/ai-system/`, AGENTS.md o perfiles de agentes.

## Validaciones

| Comando | Resultado observado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` (app/) | Exit 0; cuatro archivos revisados, ninguno cambió |
| `dart analyze lib test` (app/) | Exit 0; sin problemas |
| `flutter test --no-pub` (app/) | Exit 0; 1 widget test aprobado |
| `dart scripts/check_imports.dart --root .` (raíz) | Exit 0; los imports de dominio reales son válidos |
| `bash scripts/test_check_imports.sh` | Exit 0; positivo y árbol real pasan, diez negativos devuelven exit 1 esperado |
| `dart format scripts/check_imports.dart` | Exit 0 |
| `dart analyze scripts/check_imports.dart` | Exit 0; sin problemas |
| `flutter analyze --no-pub` (app/) | Exit 255; servidor LSP aborta con `FormatException` al procesar ruta con `í`, no se suprimió |
| `flutter run -d linux --no-pub` (app/) | Arranque debug y build Linux completados; proceso llegó a VM Service/menú interactivo. Emitió avisos ATK/GDK, fue terminado al acabar la comprobación. |
| Grafo de imports local | Sin ciclos: `main.dart → app/anime_app.dart → domain/app_identity.dart` |
| `flutter pub get` y lockfile | Exit 0; no se modificaron `pubspec.yaml` ni `pubspec.lock` |
| `bash scripts/ci.sh` | Exit 1: memory check pasa, 40 pruebas IA pasan, checker/formato/análisis Dart/dependencias/flutter_test pasan. El único fallo obligatorio es `flutter analyze` (exit 255, LSP/FormatException). |

El checker es lexical y no reemplaza un análisis semántico completo; la lista de plugins conocidos se debe mantener al aprobar nuevas integraciones. Rechaza symlinks en las raíces `app`/`app/lib` y bajo `app/lib` sin seguirlos, tanto archivos fuente como directorios. No añadimos dependencias, no cambiamos lockfile y no iniciamos F1.5/F1.6. `flutter analyze` continúa bloqueado por el problema de LSP documentado previamente; no se modificó configuración de calidad para ocultarlo.

## Pendientes

- Ejecutar el checker de memoria y el CI nuevamente tras completar este registro.
- F1.5: acordar catálogo, claves, tipos, defaults y contrato observable del registro/store de ajustes, con pruebas de valores iniciales, validación y operación offline.
- F1.6: persistencia durable Drift/SQLite, migraciones y pruebas de cierre/reinicio/rollback.
