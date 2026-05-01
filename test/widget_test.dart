import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:estinol_editor_2/providers/dictionary_provider.dart';
import 'package:estinol_editor_2/widgets/word_editor.dart';

void main() {
  Future<void> _pumpEditor(WidgetTester tester) async {
    final provider = DictionaryProvider(initChangesListener: false);
    provider.startAddingNewWord();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DictionaryProvider>.value(
            value: provider,
            child: const WordEditor(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+B wraps selection in ** **', (WidgetTester tester) async {
    await _pumpEditor(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));

    final editorField = fields.at(2);
    await tester.tap(editorField);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.descendant(of: editorField, matching: find.byType(EditableText)));
    editable.controller.text = 'hello';
    editable.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(editable.controller.text, '**hello**');
  });

  testWidgets('Ctrl+I wraps selection in * *', (WidgetTester tester) async {
    await _pumpEditor(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));

    final editorField = fields.at(2);
    await tester.tap(editorField);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.descendant(of: editorField, matching: find.byType(EditableText)));
    editable.controller.text = 'hello';
    editable.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(editable.controller.text, '*hello*');
  });
}
