# Documentación del reproductor

Esta carpeta reúne evidencia técnica del reproductor. F2.2 fue aceptada y F2.3 implementa atajos básicos en el mismo spike opt-in, aislado bajo `app/`. El trabajo no conecta el reproductor al producto ni adelanta F2.4.

| Documento | Alcance | Estado |
| --- | --- | --- |
| [F2.2-spike-report.md](F2.2-spike-report.md) | Corte técnico anterior a auditoría v2; contexto histórico del spike | Histórico |
| [F2.2-spike-report-v2.md](F2.2-spike-report-v2.md) | Correcciones de auditoría v2, aceptación formal y evidencias | Aceptado/cerrado por el propietario — 2026-11-10 |
| [Auditoría F2.3](../ai-system/audits/F2.3-audit-2026-11-10.md) | Atajos, volumen Player, coordinación de seek, foco y frontera GTK | Revisión técnica; fullscreen gráfico Fedora pendiente |

Los contratos y procedimientos específicos están en los README de `app/lib/application/player`, `app/lib/data/player/engine` y `app/lib/app/player`. F2.3 asigna Espacio/K a Play/Pause, flechas izquierda/derecha a seek de 10 s, flechas arriba/abajo a volumen local de 5 puntos, F a fullscreen GTK y Escape a salir cuando GTK confirma fullscreen. El plan de fases sigue en [ROADMAP](../../ROADMAP.md) y el estado confirmado en [PROGRESS](../../PROGRESS.md). La subfase queda abierta hasta la verificación gráfica y aceptación del propietario.

## Proveedores de episodios

El recorrido AniList ficha → episodio → selector → player existente está
conectado. AnimeAV1 y TioAnime están registrados, pero ninguna fuente probada
reprodujo en libmpv en la última validación. AnimeOnline Ninja respondió 403;
JKAnime y AnimeJara no están registrados. Estado, comandos y límites están en
[`providers/README`](../../app/lib/data/player/providers/README.md) y las guías
por proveedor. No se considera operativa esta ruta hasta reproducir un episodio
real en Fedora.

- [Operación extendida y launcher DEMO](operacion-extendida.md).

- [DEMO Morevna, controles, medios y licencias](demo-morevna.md).
