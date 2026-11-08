import 'package:anime_app/app/anime_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla inicial de AnimeApp', (tester) async {
    await tester.pumpWidget(const AnimeApp());

    expect(find.text('AnimeApp'), findsNWidgets(2));
    expect(
      find.text('Base de la aplicación lista para Linux.'),
      findsOneWidget,
    );
  });
}
