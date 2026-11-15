# Dirección visual aprobada para Home

La instrucción visual más reciente del propietario es la captura adjunta el 2026-11-14: composición de escritorio con rail izquierdo, hero panorámico con metadatos, secciones horizontales de pósteres y fondo AMOLED `#000000`. El propietario pidió mantener la composición y sustituir los iconos. Esta dirección reemplaza la referencia inicial `Kongroo_Home_Referencia_Aprobada.png` para esta iteración; no se copian su marca ni sus iconos.

La captura define rail izquierdo en escritorio, navegación inferior en Android, navegación superior en TV, hero panorámico con etiquetas de formato/temporada/puntuación, fila de continuación y estantes anchos de pósteres. El set de iconos puede cambiar manteniendo semántica simple y consistencia. La implementación limita datos personales a biblioteca local y progreso local real.

Datos personales se derivan solo de biblioteca y sesión local existentes. En emisión y Tendencias proceden del browse público AniList. Si falta el banner, no se estira una carátula en el hero. Las filas Continue watching y Currently watching se omiten cuando no hay contenido real.

PC: hover escala la imagen 1.035 dentro de su recorte sin mover el grid; muestra acciones translúcidas dentro de la carátula. El clic derecho abre el menú oscuro propio en la posición del puntero. Android y TV muestran únicamente tres puntos al pie de la carátula; TV revela el botón al enfocar y restaura el foco al cerrar el menú. La puntuación proviene de `averageScore` y no aparece si AniList no entrega un valor.

El hero avanza automáticamente cada 6 s por defecto cuando hay al menos dos destacados. La selección manual reinicia el intervalo. El movimiento reducido pausa el autoplay y quita las transiciones; también se pausa cuando la ventana/ruta no está activa o el hero deja el viewport. Los indicadores permanecen seleccionables. `Watch now` permanece deshabilitado hasta disponer de una fuente de video válida.

En escritorio, la rueda vertical dentro de un estante mueve horizontalmente ese carrusel con una animación breve, y la delta horizontal del trackpad se conserva directamente. En los límites no se consume la señal, por lo que la página puede seguir desplazándose verticalmente. Flechas, gesto táctil y navegación TV se conservan.

Los iconos de Home usan glifos outline centralizados y los estilos tipográficos usan pesos moderados, tracking reducido y la fuente sans instalada por el sistema; no se incluye una fuente propietaria.

Personalización futura registrada: visibilidad y orden de secciones, densidad, tamaño y variantes de tarjetas, altura e intensidad del banner, icon packs y perfiles Lite/Minimalista/Otaku. Son puntos de extensión documentados, aún sin editor de Ajustes.
