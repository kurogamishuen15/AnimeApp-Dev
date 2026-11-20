# Fixtures de caracterización

Datos sintéticos basados en formatos del código y fixtures de tests existentes;
no son respuestas descargadas ni contienen sesiones, cookies o tokens reales.
No se realizan solicitudes de red en estos tests.

- miruro_config.json: configuración con orden y proveedor oculto/embed.
- parser_cases.json: HTML/entidades, títulos, episodios, rechazos de URL .test,
  JSON malformado, cursor ausente, devalue válido y ciclo inválido.
- parser_public_media.json: escenario adicional con dominio example.org para
  comprobar fuentes no vacías, orden de calidades y headers. No se contacta el dominio.

Salida actual congelada en test/golden/refactor/parser_outputs.json y
parser_public_media_outputs.json mediante `dart test/refactor/parser_snapshots.dart`
(y `--public-media`) con SDK local 3.47.9; no regenerar tras un refactor.
El golden inicial de configuración también se conserva sin cambios.

Otros fixtures existentes permanecen en los tests de proveedores: AllAnime,
MegaPlay, AnimeGG, AniZone, VOE y Wikimedia. Sus tests importan el manager que
actualmente no compila; no se atribuye cobertura golden completa a esas fuentes.
JKAnime no dispone de test ni fixture directo y tiene errores de sintaxis y
contrato. Ver docs/refactor/PROTEGIDO.md y BLOQUEOS.md antes de moverlo.

## Harnesses de fuentes

Los archivos *_harness.dart conservan fixtures y adaptadores HTTP de los tests
existentes en test/data/player/providers (mismo nombre por fuente). Solo se
independizó la invocación del manager roto y se hicieron públicos nombres de
fixtures para evitar lints de elementos privados no usados. No se copió ni editó
lógica de lib. Se guardan todos los campos de fuente/candidatos/subtítulos y
peticiones emitidas, excepto la comparación de firma temporal descrita abajo.

Fuentes: AllAnime, AnimeAV1, AnimeGG, AniZone, MegaPlay, Wikimedia; resolver VOE.
Miruro además tiene decoder XOR+gzip binario y texto idéntico; direct media y
JSON de fuentes manuales tienen snapshot. JKAnime sigue SIN GOLDEN por errores
previos de sintaxis/contrato; no se contactó red para inventar un fixture.

AllAnime: la comparación de petición completa está explícitamente omitida por
B0-09 (aaReq depende de DateTime.now). Se conserva su expectativa original
sin modificar. Un test independiente compara todos los campos de fuentes;
no se afirma que eso cubra la firma temporal.

Los comandos de captura son herramientas de preparación inicial; NO regenerar
golden tras mover código. capture_sources.dart rechaza sobrescribir archivos.
