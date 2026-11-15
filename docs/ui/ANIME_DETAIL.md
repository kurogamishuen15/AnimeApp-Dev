# Referencias visuales aprobadas — ficha de anime

## Fuente de verdad

La ficha no debe reinterpretarse ni rediseñarse. Las capturas aprobadas por el
propietario tienen prioridad para proporciones, densidad, espaciado, degradados
y variantes por plataforma. La especificación textual complementaria fue
entregada como `/home/kyouma/Vídeos/instruccion.txt`.

Las rutas originales de las capturas eran temporales. En la comprobación del
2026-11-15 ninguno de esos archivos seguía disponible; por tanto, no se debe
afirmar una coincidencia píxel a píxel hasta que el propietario vuelva a
adjuntarlos. No se copiaron ni recrearon imágenes de referencia.

| Área | Plataforma | Ruta original del adjunto | Estado 2026-11-15 |
| --- | --- | --- | --- |
| Cabecera y Enlaces | PC | `/tmp/codex-clipboard-f13c30cb-c539-4423-9a07-08b8efc56a5a.png` | No disponible |
| Cabecera y Episodios | PC | `/tmp/codex-clipboard-4f4ba881-d313-45d1-b824-3f39a94c097f.png` | No disponible |
| Cabecera y Episodios | Teléfono | `/tmp/codex-clipboard-81527b93-6f1d-47c9-a729-65c5e376b124.png` | No disponible |
| Información | PC | `/tmp/codex-clipboard-30265a0a-be27-4cb6-b164-47e88df44b20.png` | No disponible |
| Información | Teléfono | `/tmp/codex-clipboard-6639d262-d06b-4fb9-b57e-a7fbfb091c10.png` | No disponible |
| Reparto | PC | `/tmp/codex-clipboard-bbb91ed9-b5b8-44dc-bf61-de5b29e54dea.png` | No disponible |
| Reparto | Teléfono | `/tmp/codex-clipboard-0505d775-28c5-4d01-833c-197f6571d072.png` | No disponible |
| Galería | Teléfono | `/tmp/codex-clipboard-4f424ccc-0dd8-40f7-89aa-accf1f4ad8f6.png` | No disponible |
| Galería | PC | `/tmp/codex-clipboard-6c9d8890-5be0-403f-a799-438a6bd4dcd7.png` | No disponible |
| Títulos relacionados | PC | `/tmp/codex-clipboard-53f66aaf-29f9-4f16-9359-82ffab6556b7.png` | No disponible |
| Títulos relacionados | Teléfono | `/tmp/codex-clipboard-18ec3f21-af9b-4af0-b192-b45f644fc344.png` | No disponible |

No se entregó una captura aislada de Títulos alternativos ni una captura de TV;
esas variantes se rigen por la especificación textual hasta disponer de una
referencia visual aprobada.

## Decisiones que deben conservarse

- Negro AMOLED `#000000`, tipografía e iconos globales actuales y acento morado
  discreto.
- Cabecera como una sola composición: banner real, fundido progresivo a negro,
  carátula superpuesta y metadatos integrados, sin panel gris intermedio.
- PC usa carátula vertical amplia y contenido alineado desde la zona superior
  útil del banner. Teléfono conserva carátula compacta, metadatos a su derecha
  y sinopsis inmediatamente debajo.
- Episodios: cuadrícula panorámica adaptable en PC/TV y filas horizontales
  compactas en teléfono.
- Información, reparto, galería, títulos alternativos y relaciones deben usar
  la densidad y proporción de sus capturas; no introducir paneles o tarjetas
  decorativas no justificadas.
- La navegación global, Home, reproductor y capas de datos quedan fuera del
  alcance de fidelidad visual de la ficha.

## Validación

La validación automatizada comprueba geometría y ausencia de desbordamientos,
pero no sustituye la comparación visual. Para declarar fidelidad se necesita:

1. volver a disponer de la referencia original;
2. abrir Kongroo real en Fedora al mismo tamaño;
3. capturar con Wayland cuando el backend esté disponible;
4. comparar referencia e implementación sección por sección;
5. detenerse para aprobación manual después de cada bloque autorizado.
