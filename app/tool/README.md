# Herramientas de desarrollo de la aplicación

`animesdigital_live_harness.dart` comprueba de forma opt-in la búsqueda del
episodio público, la resolución del manifiesto y la descarga de un segmento.
No muestra video en una ventana y no acredita reproducción.

Desde `app/`:

```bash
../.ai-local/toolchains/flutter/bin/dart run tool/animesdigital_live_harness.dart
```

`animesdigital_live_player_app.dart` es una herramienta diagnóstica que monta
la página, coordinator, engine media_kit/libmpv y superficie existentes antes
de abrir la fuente. Permite observar el estado nativo y el primer frame; no es
otro reproductor ni un test automatizado. La última ejecución abrió el HLS,
pero la ventana mostró error de decodificación y pantalla negra.

Para obtener un diagnóstico acotado con `ffprobe` ya instalado en Fedora,
ejecuta `KONGROO_LIVE_FFPROBE=1 dart tool/animesdigital_live_harness.dart 1`.
El harness informa codecs/dimensiones o un error con URLs redactadas; resume
extensiones de referencias HLS sin guardar el manifiesto ni su query. Esto ayuda
a separar transporte y demux, pero no acredita reproducción en libmpv. Una
corrida observó una referencia `.webp` rechazada por el filtro de extensiones
HLS; no se amplió el filtro y una petición posterior del provider agotó el
timeout.

```bash
../.ai-local/toolchains/flutter/bin/flutter run -d linux \
  -t tool/animesdigital_live_player_app.dart
```

El harness histórico `animeheaven_live_harness.dart` se retiró con el adapter;
sus resultados se conservan en
[`S0-REAL-PLAYBACK-REPORT.md`](../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md)
y el [archivo de READMEs retirados](../../docs/ai-system/archive/providers/S0-2026-11-16/README.md).

El spike local del reproductor sigue disponible en
[`tools/player/run_f2_2_spike.sh`](../../tools/player/run_f2_2_spike.sh). Su
objetivo es validar media_kit/libmpv con fixtures locales, no probar hosts ni
providers. La línea base ejecutada al inicio de S0-S y sus límites están en
[`S0-S-BASELINE-AND-IMPLEMENTATION.md`](../../docs/ai-system/missions/S0-S-BASELINE-AND-IMPLEMENTATION.md).

Las herramientas de providers nuevos deberán añadirse solo si acompañan un
adapter registrado y pruebas de red limitadas; nunca guardarán URLs firmadas,
cookies o credenciales en logs.
