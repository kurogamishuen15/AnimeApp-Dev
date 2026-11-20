# Inventario contractual — 2026-11-20

Captura del árbol respaldado por `507368b177a1b096ae4cfae9f3c0094f658693c8`.
No se ha cambiado lógica. Todos los elementos conservan ubicación actual.
El registro [CONTRATOS_REFERENCIAS](CONTRATOS_REFERENCIAS.md) enumera símbolos,
endpoints/cabeceras/parámetros, pantallas/rutas, persistencia y configuración.
`snapshot_api.txt` se obtiene con AST, incluyendo getters, constructores y campos;
`API_PARSE_ERRORS.txt` declara los errores sintácticos previos que limitan el AST.
Los archivos con errores conservan hash y fuente completa en el commit de respaldo:
la lista de sus símbolos es recuperada por el parser, no certificada semánticamente.
No interpretar nombres dinámicos de claves o rutas interpoladas como constantes.

| Categoría | Elementos registrados |
| --- | --- |
| símbolo | 2751 |
| endpoint/cabecera/parámetro | 264 |
| ruta/pantalla | 27 |
| persistencia | 219 |
| configuración | 34 |

## Servicios, repositorios y scrapers

Todos sus símbolos públicos están individualizados por ID en el registro;
`PROTEGIDO.md` añade callers, cobertura y hashes de los módulos protegidos.
Los servicios existentes de catálogo son AniList/Kitsu; no se sustituirán por MAL.
El identificador MyAnimeList en proveedores no acredita un catálogo MAL conectado.

## Persistencia

Se conserva Drift schemaVersion 9, tablas, migraciones y JSON opaco, identificadores,
claves de caché, settings, credenciales y progreso. El registro incluye las líneas
que los definen; el hash del archivo protege también expresiones multilinea.
No modificar esquema, codecs ni precedencia en un movimiento.

## Assets y dependencias

El manifiesto no declara assets ni fuentes de aplicación; `uses-material-design`
se conserva. Los README bajo lib no son assets runtime. Recursos de plataforma
se inventarían en PLATAFORMAS y en el mapa de todos los archivos, sin borrarlos.

```yaml
name: anime_app
description: Base Flutter de AnimeApp para Linux.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.13.7

dependencies:
  dio: ^5.11.1
  drift: ^2.35.3
  flutter_secure_storage: ^11.2.0
  flutter:
    sdk: flutter
  material_ui: ^1.10.0
  path_provider: ^2.1.5
  sqlite3: ^3.9.1
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  media_kit_libs_video: ^1.0.7
  cryptography: 2.9.0
  http2: ^3.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  drift_dev: ^2.35.2
  build_runner: ^2.17.1
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true

```

## Permisos y configuración por plataforma

Ver [PLATAFORMAS](PLATAFORMAS.md): cada configuración presente se conserva literal.
Android y Windows no verificables; no se ha añadido ningún scaffold.
