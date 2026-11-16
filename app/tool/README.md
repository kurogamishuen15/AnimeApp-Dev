# Herramientas manuales del player

## AnimeHeaven live harness

`animeheaven_live_harness.dart` es una pantalla temporal/de desarrollo para
probar el provider live desde una ventana Linux. Resuelve One Piece, episodio
1 y abre la misma `ProviderPlaybackRoute` y el mismo motor media_kit/libmpv de
la ficha. Inicia reproducción en la primera alternativa que supera el probe;
al volver al harness se pueden abrir los otros mirrors por separado. La
pantalla muestra solo IDs de mirror y no guarda ni imprime URLs efímeras.

Desde `app/`, con el SDK aislado del proyecto:

```bash
../.ai-local/toolchains/flutter/bin/flutter run -d linux --no-pub \
  -t tool/animeheaven_live_harness.dart
```

Para abrir un mirror concreto entre los candidatos validados, antepone, por
ejemplo, `KONGROO_ANIMEHEAVEN_MIRROR=mirror-ck` al comando. Si el ID solicitado
no aparece entre los candidatos, el harness informa el error y no abre otro
mirror. El proceso solo imprime los IDs de candidatos, nunca sus URI.

En One Piece, episodio 1, el servicio publicó `mirror-cx`, `mirror-ct` y
`mirror-ck`. Los tres se intentaron por separado en libmpv y mostraron un error
genérico sin frame. Capturas locales (ignoradas por Git):
`.ai-local/review/s0-animeheaven-mirror-cx.png`,
`s0-animeheaven-mirror-ck.png`, `s0r-animeheaven-visible.png` y
`s0r-animeheaven-mirror-switch.png`. No repetir este episodio sin evidencia de
que cambió la disponibilidad.

Al regresar, selecciona cada mirror por separado para verificarlo. Cierra el
player entre intentos para que el lease nativo se libere. Esta herramienta no
es la interfaz del producto ni se ejecuta en CI. `flutter test` intercepta HTTP
live y devuelve 400, así que este harness de escritorio es el recorrido real
para red/catálogo/player. La evidencia real y los límites de acceso se registran en
[`docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md`](../../docs/ai-system/missions/S0-REAL-PLAYBACK-REPORT.md).
