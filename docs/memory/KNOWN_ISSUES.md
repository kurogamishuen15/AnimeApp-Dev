# Problemas conocidos

Fuente: auditoría local autorizada y referencias enlazadas
Fecha: 2026-11-07
Módulo: infraestructura IA
Estado: vigente
Decisión: AI-002
Evidencia: ENVIRONMENT_AUDIT.md y pruebas fallidas registradas

## AI-GIT-001 — .git protegido sin repositorio operativo
Observación inicial: git rev-parse falló aunque había un directorio .git visible. Ese directorio es especial en la sesión y no acredita un repositorio. No usar reset ni borrar .git. Solución prevista: comprobar directorio del proyecto mediante ejecución autorizada, inicializar solo si realmente no existe repositorio y crear rama ai/setup-autonomous-environment. El resultado final se registra en FINAL_REPORT.md; esta sección conserva el fallo inicial.

## AI-RUN-001 — No hay imagen aislada ni proveedor preparados
Podman rootless funciona en el anfitrión tras ejecución autorizada, pero no en el sandbox de esta sesión. No hay imágenes locales en la inspección inicial. Un modo nocturno real requiere imagen verificada, proveedor sin exponer credenciales y prueba completa. Los tests con dobles no lo acreditan.

## AI-DATA-001 — Sin código de producto
No pueden verificarse pruebas Flutter, módulos funcionales, decisiones ni rendimiento de AnimeApp aquí. Esperar una misión que aporte código autorizado en esta carpeta.
