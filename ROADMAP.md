# Hoja de ruta AnimeApp

La numeración oficial es la del plan original. Esta hoja resume el orden y las dependencias conocidas; `PROGRESS.md` conserva el estado real de cada subfase.

## Dependencias entre fases

```text
F0 preparación
  └─ F1 núcleo
      ├─ F2 reproductor ─┐
      ├─ F3 UI ──────────┴─ F4 catálogo y funciones
      ├─ F5 plataformas y sincronización (parte posterior depende de F1/F4)
      └─ F6 ajustes y descargas (depende de módulos previos)
F7 estabilización ← resultados de las fases anteriores
```

La guía original sitúa el MVP después de integrar el núcleo, el reproductor mock y la UI mínima. No se adelantan funciones entre fases sin registrar y aprobar el cambio.

## F0 Preparación Fedora

| ID | Entregable |
| --- | --- |
| F0.1 | Verificar Fedora, Flutter/toolchain Linux, GTK, libsecret y disponibilidad de libmpv sin instalar paquetes sin autorización. |
| F0.2 | Git raíz, `.gitignore`, ramas/commits y separación privado/público. |
| F0.3 | Ocho documentos Markdown requeridos (README y siete referencias) completados y enlazados; D3/LICENSE se registra pendiente sin bloquear la subfase. |
| F0.4 | Esqueleto Flutter Linux mínimo, lints y ventana comprobada. |
| F0.5 | CI local reproducible y comprobación de imports con prueba positiva/negativa. |
| F0.6 | Línea base reproducible de inicio de proceso/ventana y RSS, con limitaciones registradas. |

## F1 Núcleo

F1.1 requisitos (aprobados: [18 FR, 13 NFR y trazabilidad](docs/requirements/F1.1-CORE-REQUIREMENTS.md)) → F1.2 decisiones tecnológicas (14 selecciones aprobadas como referencia; validaciones pendientes: [ADR](docs/adr/README.md)) → F1.3 arquitectura → F1.4 estructura modular → F1.5 registro de ajustes → F1.6 Drift → F1.7 errores/logs → F1.8 cliente AniList GraphQL de lectura → F1.9 OAuth/almacén seguro → F1.10 progreso local → F1.11 contrato de sincronización/FakeRemote → F1.12 pruebas del núcleo.

## F2 Reproductor

F2.1 evaluación de motores → F2.2 spike media_kit → F2.3 controles → F2.4 sesión/estados → F2.5 contrato y proveedor mock → F2.6 subtítulos internos → F2.7 cambio de fuente → F2.8 subtítulos externos → F2.9–F2.10 saltos → F2.11 rendimiento y estabilidad.

## F3 UI y funciones posteriores

F3.1 componentes visuales → F3.2 layouts → F3.3 navegación → F3.4 Lite → F3.5 Base → F3.6 packs → F3.7 recursos visuales → F3.8 escalas → F3.9 usabilidad.

F4 cubre Home, búsqueda, descubrimiento/filtros, calendario, biblioteca, ficha, episodios, recomendaciones y selector aleatorio (F4.1–F4.10). F5 incorpora plataformas y sincronización (F5.1–F5.9; backend y cliente se prueban por separado). F6 incorpora ajustes, descargas y copias de seguridad (F6.1–F6.12). F7 mide, estabiliza y audita (F7.1–F7.10).

## Cambios y bloqueos

Las condiciones externas (servicios, drivers, APIs y permisos) se registran junto a la subfase afectada. Una modificación del orden debe explicar motivo, alternativas y consecuencias y esperar aprobación si cambia decisiones previas. No se rebautizan ni renumeran fases.
