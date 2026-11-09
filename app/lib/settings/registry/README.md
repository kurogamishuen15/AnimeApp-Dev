# Registro de ajustes

Este módulo Dart define ajustes tipados sin importar Flutter, Drift, Dio ni
plugins. Cada `SettingDefinition<T>` declara clave estable, propietario,
default, codec JSON y validador. `SettingsRegistry` exige registro único y
rechaza definiciones no registradas o distintas de la instancia aprobada.

No se registran todavía preferencias de producto: el plan y ADR-A06 no fijan
nombres, defaults ni alcance de sincronización. Los tipos usados en tests son
fixtures y no decisiones aprobadas. No guardar tokens aquí; corresponde al
almacén seguro de F1.9.

Para portar a otro cliente, reutilizar las definiciones/reglas Dart y
proporcionar un adaptador de almacenamiento que cumpla el contrato; nunca
importar Drift o Flutter en dominio.
