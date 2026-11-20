# Wikimedia Commons

El catálogo revisado contiene la película completa *Namakura Gatana* (1917),
vinculada por AniList 6654 a Wikidata Q2054133. El adaptador consulta la API
oficial de Commons para obtener las transcodificaciones actuales. Exige que el
archivo esté identificado como de dominio público y entrega únicamente WebM
de `upload.wikimedia.org` en el espacio `/wikipedia/commons/`.

La coincidencia por ID restringe el alcance a esa película y a su episodio
único. Kitsu aporta el registro de episodio que usa la ficha. Las URLs y
resoluciones vienen de la API. El adaptador está deshabilitado por defecto y se
activa explícitamente con `KONGROO_ENABLE_WIKIMEDIA=1`.

Fuentes [AniList](https://anilist.co/anime/6654),
[Wikidata](https://www.wikidata.org/wiki/Q2054133),
[archivo y licencia](https://commons.wikimedia.org/wiki/File:Kouichi_Jun%27ichi_-_Namakura_Gatana_%281917%29_-_4-minute_restored_version.webm)
y [MediaWiki Action API](https://www.mediawiki.org/wiki/API:Query).

## Transporte remoto verificado

El UA de Kongroo se aplica a la API y a cada WebM enviado a libmpv.
El catálogo prefiere 480p y reutiliza los derivados públicos durante 5 min.
La API respeta el plazo Retry-After cuando limita las consultas. Fedora
mostró cuadros remotos con seek a 20 s desde el módulo de producto en el
[lanzador de diagnóstico](../../../../../../docs/ai-system/missions/OC03-1-REMOTE-TRANSPORT-2026-11-16.md).
