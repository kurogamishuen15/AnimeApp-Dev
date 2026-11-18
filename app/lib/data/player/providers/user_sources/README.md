# Fuentes definidas por el usuario

Proveedor `user-defined`. Sirve solo los episodios que el propio usuario
registra en un archivo JSON local. No busca anime, no raspa páginas y no contiene
URLs de terceros.

## Uso

1. Crea un archivo JSON con este formato:

```json
{"sources":[
  {"anime":"anilist:21","episode":1,"url":"https://ejemplo.org/video.m3u8","language":"ja","quality":"720p"}
]}
```

- `anime`: ID local del anime o `<proveedor>:<id>` (por ejemplo `anilist:21`).
- `episode`: número de episodio (entero ≥ 1).
- `url`: solo `https`, sin fragmento. Entradas inválidas hacen fallar el análisis completo.
- `language` y `quality` son opcionales (`unknown` y `Auto` por defecto).

2. Arranca Kongroo con `KONGROO_USER_SOURCES=/ruta/absoluta/fuentes.json`.
   Si la variable no existe, el proveedor no se registra. Si el archivo es
   inválido, se informa por stderr y la app arranca sin esas fuentes.

## Contrato

- Implementa `PlaybackSourceProvider` y se registra en `PlaybackProvidersModule`.
- Emite un `PlaybackSource` por entrada coincidente, con `DirectMediaHostResolver`
  como host. La reproducción pasa por el mismo manager, resolutor y motor media_kit.
- Sin coincidencia devuelve `PlaybackProviderEmpty`.

## Límites

- Una URL registrada no prueba que el vídeo esté disponible ni que tenga fotogramas.
  Eso se confirma solo con reproducción real.
- Kongroo no verifica licencias ni derechos de los contenidos: la responsabilidad
  de cada URL es del usuario.
