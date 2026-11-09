# Settings

Módulo funcional local-first de ajustes. Los contratos genéricos y la
validación viven en [`registry`](registry/README.md); la lectura/escritura
reactiva SQLite vive en [`store`](store/README.md).

No hay definiciones de preferencias de producto registradas todavía porque los
documentos aprobados no establecen nombres, defaults ni alcance de
sincronización. Los ejemplos de tests son fixtures. Las credenciales están
excluidas y deben usar el secure store de F1.9.
