# Home

Home presenta metadatos de catálogo público y datos personales únicamente cuando existen en contratos locales.

| Archivo | Responsabilidad |
| --- | --- |
| `home_screen.dart` | Estados carga, vacío, error y composición de secciones. |
| `home_data.dart` | Modelos de UI y unión del catálogo público con biblioteca y progreso local. |
| `home_hero.dart` | Banner panorámico, destacados navegables, metadatos reales, autoplay y degradado a negro AMOLED. |
| `home_sections.dart` | Estantes bajo demanda y tarjetas con zoom hover recortado; filas personales vacías se omiten. |
| `home_card_actions.dart` | Contrato y permisos compartidos; menú de escritorio oscuro refinado y hoja móvil con estado marcado, quitar y copiar enlace AniList. |
| `home_score_badge.dart` | Badge refinado de score real con estrella dorada de alto contraste; se omite cuando no hay score. |
| `home_typography.dart` | Escala, pesos y tracking sobrios basados en la fuente sans del sistema. |
| `home_artwork.dart` | Carga HTTPS por ancho de presentación, decodificación limitada y fallback accesible. |
| `home_icons.dart` | IDs semánticos estables para navegación, detalle, opciones y estados de biblioteca; paquete minimalista predeterminado. |
| `home_appearance.dart` | Tokens AMOLED y acento morado con `ThemeExtension`. |

`CatalogHomeSource` consume `CatalogService`. Home no conoce GraphQL, Dio ni SQLite. Populares y tendencias consultan AniList público mediante `MetadataProvider` y `PublicAnimeBrowseProvider`. Biblioteca y progreso permanecen locales y separados de cualquier cuenta AniList. Las secciones Continue watching y Currently watching se omiten completas si no hay registros locales; no se crean entradas personales. El CTA Watch now se muestra deshabilitado hasta que exista una fuente de reproducción válida.

## Tarjetas e interacciones

Las tarjetas conservan sus constraints, proporciones y texto. Estado normal: carátula limpia más badge de puntuación cuando AniList entrega `averageScore`. En PC, hover o foco muestra cápsulas independientes translúcidas, sin placa negra compartida, y una escala de imagen de 1.035 durante 160 ms. El `ClipRect` mantiene el zoom dentro del marco; solo se transforma el póster, sin reflow, sombra difusa, blur ni cargas de imagen. El clic derecho abre el menú completo en la posición del puntero, incluso sin activar los controles hover.

En TV (Android con navegación direccional), el foco del mando dibuja un indicador y revela únicamente tres puntos al pie de la carátula. El menú se abre con Aceptar/Enter; Atrás/Escape lo cierra y devuelve el foco al control. En teléfono Android queda visible únicamente ese botón, con objetivo táctil de 48 px; tocar el resto abre Details. El botón evita propagar su toque a la tarjeta. En PC el clic derecho abre el menú completo sin depender del hover.

Los tres formatos comparten `HomeCardActionPolicy` y el callback de `CatalogHomePage`. En PC/TV, el menú propio usa superficie AMOLED, esquinas suaves, separadores discretos y tipografía ligera, sin `PopupMenuItem` de Material. El menú ofrece Details, estado actual marcado, los seis estados locales, Remove from list cuando existe membership y Copy link cuando AniList expone un ID público numérico. `Plan to watch` agrega y enlaza la identidad local a partir de metadata resuelta. Los estados se representan como Watching, Plan to watch, Rewatching, Paused, Completed y Dropped. Quitar membership conserva identidad/progreso. Marcar Completed solicita confirmación sobre episodios que Kongroo no puede verificar. Home no ofrece reproducir porque aún no existe una fuente válida.

`HomeCardActionPolicy` desacopla permisos de la presentación. `HomeAppearance` ofrece tokens de sobreposición, radios, familia tipográfica, escala e intervalo configurable del banner. El autoplay usa 6 s por defecto, se reinicia tras la selección manual y se pausa con movimiento reducido, puntero/foco sobre el hero, ventana inactiva o hero fuera del viewport. El `Timer` se cancela al desmontar el componente. `HomeTypography` usa pesos/tracking limpios y la fuente de sistema, sin archivos propietarios ni descargas. `HomeIcons` centraliza glifos outline consistentes. Lite puede reducir animación; Minimalista puede cambiar iconos/estilos sin alterar contratos. `HomeContent.highlights` prepara el banner para configuración futura de destacados. Cada tarjeta guarda hover/foco local; las filas usan construcción diferida. Las pruebas cubren clic derecho, escala/clip, badge, menú, estados, opciones móviles, foco/D-pad, retorno, estados vacíos, autoplay y desplazamiento horizontal.

Las imágenes se solicitan con HTTPS desde AniList. Flutter `ImageCache` se limita en el arranque a 120 entradas y 48 MiB. Cada imagen se decodifica a un ancho físico máximo de 1600 px. Las filas usan construcción diferida, gesto táctil, flechas y desplazamiento con rueda/trackpad sobre PC. Rueda vertical se traduce a avance horizontal suave mientras haya recorrido; si el carrusel ya llegó al borde, el gesto queda disponible para el scroll vertical de la página. No dibujan una barra permanente que tape la tarjeta. El banner solo utiliza `bannerImageUrl`; su ausencia omite el banner visual.

El shell usa rail lateral en escritorio, navegación inferior en superficies compactas y navegación superior cuando Android informa modo direccional de TV. Esta modalidad de TV aún requiere prueba en dispositivo. Las preferencias de orden/visibilidad, densidad, variante de tarjeta, tamaño del banner, intensidad del degradado, tipografía y paquete de iconos son extensión futura, sin editor implementado. Consulte [la dirección visual actual](../../../../docs/ui/HOME.md).

## Pruebas y ejecución

Desde `app/`, ejecutar `flutter test --no-pub test/home test/widget_test.dart test/data/anilist` y `flutter analyze --no-pub`. La prueba externa real se ejecuta separada de fixtures HTTP y puede depender de red, disponibilidad y límites de AniList.
