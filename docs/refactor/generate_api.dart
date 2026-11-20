import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  final output = <String>[];
  final errors = <String>[];
  final widgets = <String>[];
  final paths = Directory('app/lib').listSync(recursive: true, followLinks: false)
      .whereType<File>().where((f) => f.path.endsWith('.dart')).toList()
    ..sort((a,b) => a.path.compareTo(b.path));
  for (final file in paths) {
    final source = file.readAsStringSync();
    final parsed = parseString(content: source, path: file.path, throwIfDiagnostics: false);
    for (final error in parsed.errors) {
      errors.add('${file.path}: ${error.toString()}');
    }
    void visit(AstNode node, bool privateOwner) {
      String? name;
      int? end;
      if (node is CompilationUnitMember && node is! FunctionDeclaration) {
        name = RegExp(r'\b(?:class|enum|mixin|extension(?: type)?|typedef)\s+([\w$]+)').firstMatch(node.toSource())?.group(1);
      }
      if (node is FunctionDeclaration) name = node.name.lexeme;
      if (node is EnumConstantDeclaration) name = node.name.lexeme;
      if (node is MethodDeclaration) {name = node.name.lexeme; end = node.body.offset;}
      if (node is ConstructorDeclaration) {name = node.name?.lexeme ?? 'new'; end = node.body.offset;}
      if (node is VariableDeclaration) {name = node.name.lexeme; end = node.end;}
      if (node is FunctionDeclaration) end = node.functionExpression.body.offset;
      final hidden = privateOwner || (name?.startsWith('_') ?? false);
      if (name != null && !hidden) {
        final line = parsed.lineInfo.getLocation(node.offset).lineNumber;
        String signature;
        if (node is CompilationUnitMember && node is! FunctionDeclaration) {
          signature = source.substring(node.offset, node.end).split('{').first.trim();
        } else {
          signature = source.substring(node.offset, end ?? node.end).trim();
        }
        output.add('${file.path}:$line: ${signature.replaceAll(RegExp(r'\s+'), ' ')}');
      }
      if (node is FunctionBody) return;
      for (final child in node.childEntities.whereType<AstNode>()) {
        visit(child, hidden);
      }
    }
    visit(parsed.unit, false);
    for (final node in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final header = node.toSource().split('{').first;
      if (RegExp(r'extends\s+(?:State(?:<|\b)|StatelessWidget|StatefulWidget|ConsumerWidget)').hasMatch(header)) {
        final start = parsed.lineInfo.getLocation(node.offset).lineNumber;
        final end = parsed.lineInfo.getLocation(node.end).lineNumber;
        widgets.add('${file.path}:$start:$end: $header');
      }
    }
  }
  File('docs/refactor/snapshot_api.txt').writeAsStringSync('${output.join('\n')}\n');
  File('docs/refactor/API_PARSE_ERRORS.txt').writeAsStringSync('${errors.join('\n')}\n');
  File('docs/refactor/WIDGET_SIZES.txt').writeAsStringSync('${widgets.join('\n')}\n');
  print('${paths.length} Dart files; ${output.length} public declarations; ${errors.length} parse diagnostics');
}
