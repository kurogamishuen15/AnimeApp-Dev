import 'package:material_ui/material_ui.dart';

/// Completion remains a user-confirmed choice because the app does not yet
/// track every episode watched for a title.
Future<bool> confirmCompletedStatus(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar como completado'),
        content: const Text(
          'Kongroo todavía no puede verificar que todos los episodios se hayan '
          'visto. ¿Quieres guardar Completados manualmente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Marcar completado'),
          ),
        ],
      ),
    ) ??
    false;
