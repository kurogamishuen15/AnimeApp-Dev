# Preparar y publicar versiones de AnimeApp

Este documento define el flujo previsto para publicar versiones estables. No crea repositorios, remotos ni automatizaciones. Cada publicación requiere autorización explícita del propietario.

## Repositorios

- `AnimeApp-Dev` será privado y contendrá el trabajo completo de desarrollo.
- `AnimeApp` será público y contendrá únicamente código fuente revisado para versiones aprobadas, documentación pública y referencias a sus artefactos.
- El repositorio público tendrá historial controlado e independiente. No se transferirá automáticamente el historial privado ni se sincronizarán sus ramas.

El mecanismo técnico concreto para preparar ese historial público todavía debe aprobarse. Antes de hacerlo, se documentarán los pasos reproducibles y una forma de comprobar que la versión pública corresponde al código revisado.

La publicación debe usar una selección explícita de archivos aprobados para esa versión. No se publicará copiando o sincronizando todo el repositorio privado, usando `.gitignore` como frontera de privacidad ni arrastrando automáticamente su historial. Cada archivo de la selección pública se revisará individualmente.

## Preparación de una candidata

1. Seleccionar una subfase o conjunto de cambios aprobado y confirmar su estado, pruebas y documentación.
2. Revisar cambios, dependencias, licencias, avisos de terceros, secretos, datos privados, archivos internos y experimentos.
3. Preparar el código fuente publicable sin arrastrar automáticamente el historial privado.
4. Compilar solo plataformas aprobadas y registrar sistema, arquitectura, herramientas y resultado.
5. Probar la instalación y ejecución de cada artefacto disponible; documentar limitaciones y plataformas aún no soportadas.
6. Preparar notas con versión, fecha, cambios, correcciones, plataformas, limitaciones, dependencias y licencias.
7. Presentar el candidato al propietario para aprobación explícita.
8. Tras aprobación, publicar el código revisado y adjuntar binarios a GitHub Releases. No incorporar binarios grandes al historial Git.
9. Registrar la etiqueta, el commit o referencia fuente y los hashes de artefactos, junto con las comprobaciones realizadas.

No se publicará automáticamente desde el repositorio privado. No se configurarán remotos ni se ejecutarán `push`, creación de Release o cambios de visibilidad sin autorización específica.

## Licencias y archivos internos

Antes de distribuir, comprobar licencias y avisos de cada dependencia y biblioteca nativa incluida, además de las condiciones aplicables a su forma de empaquetado. La licencia del proyecto sigue pendiente de decisión; no declarar una licencia hasta que el propietario la apruebe y se incluya correctamente.

Excluir del material público credenciales, archivos locales, índices y respaldos privados, configuración local de herramientas, documentos internos de coordinación y experimentos no aprobados. `docs/ai-system/ENVIRONMENT_AUDIT.md` y `docs/ai-system/MCP_RESEARCH.md` son documentos internos del repositorio privado y quedan fuera de cualquier publicación pública, salvo aprobación expresa de una versión revisada y depurada.

Revisar cada archivo candidato; `.gitignore` y los escáneres automáticos no bastan para garantizar que el paquete esté limpio. Mantener una lista permitida específica por versión y conservar el resultado de su revisión antes de publicar.

## Versionado y artefactos

Se propone `v0.x.y` durante el desarrollo inicial y `v1.0.0` cuando el propietario declare una primera versión estable. La política final de compatibilidad y versionado debe documentarse antes del primer Release.

Cada artefacto debe identificar aplicación, versión, plataforma y arquitectura. Publicar únicamente plataformas soportadas y verificadas. No afirmar compatibilidad general con Fedora u otras distribuciones Linux a partir de una compilación aislada.

## Lista de publicación

- [ ] Aprobación explícita de la versión y del contenido público.
- [ ] Fuente revisada y correspondencia con una referencia concreta.
- [ ] Pruebas aplicables y comprobación manual por plataforma registradas.
- [ ] Rendimiento medido según objetivos vigentes cuando corresponda.
- [ ] Secretos, datos privados y archivos internos revisados.
- [ ] Licencias, avisos y dependencias nativas revisados.
- [ ] Instaladores verificados y notas de versión completas.
- [ ] Hashes de artefactos y limitaciones registradas.
- [ ] Publicación realizada manualmente con autorización.
