# Herramientas de desarrollo de la aplicación

Las herramientas `tool/` son diagnósticos opt-in. Ninguna registra un segundo
reproductor ni modifica el flujo normal de la app.

## Player local y diagnóstico de fuentes

El spike local se ejecuta mediante
[`tools/player/run_f2_2_spike.sh`](../../tools/player/run_f2_2_spike.sh) y usa
fixtures locales con el engine actual `media_kit/libmpv`. El harness histórico
de AnimesDigital y el harness de AnimeHeaven se retiraron junto con sus
adaptadores. Sus resultados siguen en los informes y auditorías enlazados desde
[`docs/ai-system/archive/providers/S0-2026-11-16/README.md`](../../docs/ai-system/archive/providers/S0-2026-11-16/README.md).

`commons_live_player_app.dart` monta el módulo de producto y el player actual
para validar *Namakura Gatana* de Wikimedia, integración externa que conserva
su registro opt-in. La evidencia de video remoto visible y seek de esa prueba
está en el checkpoint
[`OC03-1-REMOTE-TRANSPORT-2026-11-16.md`](../../docs/ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md).

Miruro tiene actualmente tests offline de API/parser/provider. Sus GET públicos
de catálogo devolvieron HTTP 403; no se generó un harness de evasión y no hay
reproducción externa de anime confirmada. Ver
[`providers/miruro/README.md`](../lib/data/player/providers/miruro/README.md)
y la [auditoría OC-03 de migración](../../docs/ai-system/audits/OC03-MIRURO-MIGRATION-audit-2026-11-17.md).

## Convenciones

- Un harness de red debe ser acotado, opt-in, no registrar URLs firmadas y
  respetar cancelación, límites y errores del transporte.
- Una API que responde o una posición que avanza no basta para declarar video:
  verificar cuadro real y, cuando proceda, audio y seek.
- No usar estos diagnósticos para resolver CAPTCHA, challenges, DRM, auth ni
  emular sesiones de navegador.
- Documentar pruebas desde `app/` con el SDK que realmente se ejecutó.

## Recorrido nativo de anime por la interfaz

`integration_test/anime_playback_live_test.dart` abre `main()` y recorre la
búsqueda, ficha, episodio 9 de Tokyo Ghoul:re, selector de MegaPlay, video,
seek, progreso y retorno. Usa red real y una ventana Linux, con entrada
sintética del framework. Requiere opt-in y base de datos aislada. El estado
guardado permite volver a ejecutarlo para comprobar la reanudación.

Desde `app/`, con el códec opcional ya descargado:

```bash
kongroo_project_root="$(cd .. && pwd -P)"
KONGROO_LIVE_ANIME_TEST=1 \
KONGROO_DATABASE_PATH="$kongroo_project_root/.ai-local/bee-fix/gui.sqlite" \
LD_LIBRARY_PATH="$kongroo_project_root/.ai-local/native-codecs/openh264-2.6.0" \
../.ai-local/toolchains/flutter/bin/flutter test \
  integration_test/anime_playback_live_test.dart -d linux --no-pub
```

El [lanzador Linux](../../tools/player/run_kongroo_linux.sh) permite
activar/desactivar el códec por proceso y descargarlo separadamente desde Cisco.

### Matriz de variantes e idiomas

El recorrido acepta `KONGROO_TEST_PROVIDER=megaplay|megaplay-dub`,
`KONGROO_TEST_ANILIST_ID`, `KONGROO_TEST_ANIME_TITLE`,
`KONGROO_TEST_EPISODE` y `KONGROO_TEST_CAPTION_LANGUAGE=en|es`.
La selección de idioma se realiza en el diálogo real. El caso español comprueba
además `sub-text` nativo a 00:43 para distinguir descargar VTT de mostrar texto.
Use rutas absolutas canónicas sin `..` en KONGROO_DATABASE_PATH.
`KONGROO_ENABLE_MIRURO=0` excluye su 403 conocido de esta matriz.
Ejemplos verificados y limitaciones se registran en
[la auditoría de idiomas](../../docs/ai-system/audits/OC04-LANGUAGES-audit-2026-11-17.md).
