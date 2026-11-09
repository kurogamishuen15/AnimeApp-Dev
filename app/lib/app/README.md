# Módulo `app`

## Propósito y responsabilidad

Compone la interfaz Flutter activa y proporciona el widget raíz. No contiene reglas de negocio, casos de uso, almacenamiento ni conexiones externas.

## Archivos y contratos

| Archivo | Función |
| --- | --- |
| `anime_app.dart` | `AnimeApp`, widget raíz con `MaterialApp` y pantalla inicial privada `_WelcomePage`. |

Contrato público actual: `AnimeApp({Key? key})`. `main.dart` lo instancia como raíz. `_WelcomePage` es detalle interno y no se exporta.

## Dependencias y flujo

Depende de Flutter Material y del valor Dart puro `AppIdentity.name`. El arranque único está en `../main.dart`: invoca `runApp(const AnimeApp())`; la instrumentación opt-in de F0.6 permanece en el punto de entrada. El dominio no depende de este módulo.

No usar desde aquí Drift/SQL, Dio/HTTP, credenciales, Supabase, `media_kit` ni APIs nativas. Las futuras acciones de usuario deben pasar por casos de uso/estado cuando F1.5+ los implementen; no se añaden contenedores de inyección vacíos.

## Pruebas y rendimiento

`../../test/widget_test.dart` verifica el texto de la pantalla inicial. No prueba catálogo ni ajustes. El widget no inicializa servicios pesados ni tareas de fondo; si se introducen recursos asíncronos, el responsable debe cancelar y liberar suscripciones/controladores.

## Portabilidad y pendientes

El widget es Dart/Flutter reutilizable; el host actual es el runner Linux en `app/linux/`. Android, Android TV y Windows no tienen adaptadores ni código aquí. Al incorporar otro destino se verifican controles, dimensiones, ciclo de vida, semántica y pruebas del host sin mover reglas de dominio a este módulo.
