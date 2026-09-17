import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplecalculator/main.dart';

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(Key('button-$label')));
    await tester.pump();
  }

  String display(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('calculator-display'))).data!;

  testWidgets('shows one complete calculator screen', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.text('Calculator'), findsOneWidget);
    for (final label in [
      'AC',
      '⌫',
      '%',
      '÷',
      '7',
      '8',
      '9',
      '×',
      '4',
      '5',
      '6',
      '−',
      '1',
      '2',
      '3',
      '+',
      '±',
      '0',
      '.',
      '=',
    ]) {
      expect(find.byKey(Key('button-$label')), findsOneWidget);
    }
  });

  testWidgets('performs chained arithmetic', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['1', '2', '+', '7', '×', '2', '=']) {
      await tap(tester, label);
    }
    expect(display(tester), '38');
  });

  testWidgets('multiply button uses the x operator', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['6', '×', '7', '=']) {
      await tap(tester, label);
    }
    expect(display(tester), '42');
  });

  testWidgets('handles decimal, sign, percent, and clear', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['5', '.', '5', '±']) {
      await tap(tester, label);
    }
    expect(display(tester), '-5.5');
    await tap(tester, '%');
    expect(display(tester), '-0.055');
    await tap(tester, 'AC');
    expect(display(tester), '0');
  });

  testWidgets('reports divide by zero without crashing', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final label in ['8', '÷', '0', '=']) {
      await tap(tester, label);
    }
    expect(display(tester), 'Error');
    expect(find.text('Cannot divide by zero'), findsOneWidget);
  });

  testWidgets('two plus two', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final label in ['2', '+', '2', '=']) {
      await tap(tester, label);
    }

    expect(display(tester), '4');
  });


  testWidgets('8  + 5, then divided by 0', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final label in ['8','+','5',]) {
      await tap(tester, label);
    }
    expect(display(tester), '13');

    for (final label in [ '/', '0', '=']){
      await tap(tester, label);
    }

    expect(display(tester), 'Error');
  });

  testWidgets('8 times 7, but swapping from + to * before pressing 7', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final label in ['8', '+', 'x', '7', '=']) {
      await tap(tester, label);
    }

    expect(display(tester), '56');
  });

}
