import 'package:anime_app/app/catalog/confirm_completed_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('manual completion explains unavailable episode verification', (
    tester,
  ) async {
    bool? decision;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                decision = await confirmCompletedStatus(context);
              },
              child: const Text('Completar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no puede verificar que todos los episodios'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(decision, isFalse);

    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar completado'));
    await tester.pumpAndSettle();
    expect(decision, isTrue);
  });
}
