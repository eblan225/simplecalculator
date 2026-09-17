import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Calculator',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111218),
      useMaterial3: true,
    ),
    home: const CalculatorScreen(),
  );
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _storedValue;
  String? _pendingOperator;
  double? _repeatValue;
  String? _repeatOperator;
  bool _startNewNumber = true;
  bool _showingResult = false;

  static const _symbols = {'/': '÷', 'x': '×', '-': '−', '+': '+'};

  void _inputDigit(String digit) => setState(() {
    if (_startNewNumber || _display == 'Error') {
      _display = digit;
      _startNewNumber = false;
    } else if (_display == '0') {
      _display = digit;
    } else if (_display.length < 14) {
      _display += digit;
    }
    _showingResult = false;
  });

  void _inputDecimal() => setState(() {
    if (_startNewNumber || _display == 'Error') {
      _display = '0.';
      _startNewNumber = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
    _showingResult = false;
  });

  void _chooseOperator(String operator) => setState(() {
    final current = double.tryParse(_display);
    if (current == null) return;
    if (_pendingOperator != null && !_startNewNumber) {
      final result = _calculate(_storedValue!, current, _pendingOperator!);
      if (result == null) return _setError();
      _storedValue = result;
      _display = _format(result);
    } else {
      _storedValue = current;
    }
    _pendingOperator = operator;
    _expression = '${_format(_storedValue!)} ${_symbols[operator]}';
    _startNewNumber = true;
    _showingResult = false;
    _repeatOperator = null;
    _repeatValue = null;
  });

  void _equals() => setState(() {
    if (_display == 'Error') return;
    final current = double.tryParse(_display);
    if (current == null) return;
    final operator = _pendingOperator ?? _repeatOperator;
    final right = _pendingOperator != null ? current : _repeatValue;
    final left = _pendingOperator != null ? _storedValue : current;
    if (operator == null || right == null || left == null) return;
    final result = _calculate(left, right, operator);
    if (result == null) return _setError();
    _expression = '${_format(left)} ${_symbols[operator]} ${_format(right)} =';
    _display = _format(result);
    _repeatOperator = operator;
    _repeatValue = right;
    _storedValue = null;
    _pendingOperator = null;
    _startNewNumber = true;
    _showingResult = true;
  });

  double? _calculate(double left, double right, String operator) =>
      switch (operator) {
        '+' => left + right,
        '-' => left - right,
        'x' => left * right,
        '/' => right == 0 ? null : left / right,
        _ => null,
      };

  void _clear() => setState(() {
    _display = '0';
    _expression = '';
    _storedValue = null;
    _pendingOperator = null;
    _repeatValue = null;
    _repeatOperator = null;
    _startNewNumber = true;
    _showingResult = false;
  });

  void _backspace() => setState(() {
    if (_startNewNumber || _display == 'Error') return;
    _display = _display.length > 1
        ? _display.substring(0, _display.length - 1)
        : '0';
    if (_display == '-') _display = '0';
  });

  void _toggleSign() => setState(() {
    final value = double.tryParse(_display);
    if (value == null || value == 0) return;
    _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
  });

  void _percent() => setState(() {
    final value = double.tryParse(_display);
    if (value == null) return;
    _display = _format(value / 100);
    _startNewNumber = true;
  });

  void _setError() {
    _display = 'Error';
    _expression = 'Cannot divide by zero';
    _storedValue = null;
    _pendingOperator = null;
    _startNewNumber = true;
  }

  String _format(double value) {
    if (!value.isFinite) return 'Error';
    if (value.abs() < 1e-12) return '0';
    if (value == value.truncateToDouble() && value.abs() < 1e14) {
      return value.toInt().toString();
    }
    final text = value.toStringAsPrecision(12);
    if (text.contains('e')) return text.replaceFirst('e', 'E');
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.character?.toLowerCase();
    if (key != null && RegExp(r'^[0-9]$').hasMatch(key)) _inputDigit(key);
    if (key == '.') _inputDecimal();
    if (const ['+', '-', 'x', '/'].contains(key)) _chooseOperator(key!);
    if (key == '=' || event.logicalKey == LogicalKeyboardKey.enter) _equals();
    if (key == '%') _percent();
    if (event.logicalKey == LogicalKeyboardKey.backspace) _backspace();
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _clear();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: Color(0xFF8F88FF)),
                      SizedBox(width: 10),
                      Text(
                        'Calculator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 4,
                    child: _Display(
                      expression: _expression,
                      value: _display,
                      showingResult: _showingResult,
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: _Keypad(
                      onDigit: _inputDigit,
                      onOperator: _chooseOperator,
                      onDecimal: _inputDecimal,
                      onEquals: _equals,
                      onClear: _clear,
                      onBackspace: _backspace,
                      onToggleSign: _toggleSign,
                      onPercent: _percent,
                      selectedOperator: _pendingOperator,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Display extends StatelessWidget {
  const _Display({
    required this.expression,
    required this.value,
    required this.showingResult,
  });
  final String expression;
  final String value;
  final bool showingResult;

  @override
  Widget build(BuildContext context) => Semantics(
    label: showingResult ? 'Result $value' : 'Display $value',
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            expression.isEmpty ? ' ' : expression,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9B9DA8), fontSize: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              key: const Key('calculator-display'),
              style: const TextStyle(
                fontSize: 64,
                height: 1,
                fontWeight: FontWeight.w300,
                letterSpacing: -2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onOperator,
    required this.onDecimal,
    required this.onEquals,
    required this.onClear,
    required this.onBackspace,
    required this.onToggleSign,
    required this.onPercent,
    required this.selectedOperator,
  });
  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onDecimal,
      onEquals,
      onClear,
      onBackspace,
      onToggleSign,
      onPercent;
  final String? selectedOperator;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['AC', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final label in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: _CalculatorButton(
                        label: label,
                        selected: _isSelected(label),
                        onPressed: () => _press(label),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isSelected(String label) =>
      const {'÷': '/', '×': 'x', '−': '-', '+': '+'}[label] == selectedOperator;

  void _press(String label) {
    if (RegExp(r'^\d$').hasMatch(label)) return onDigit(label);
    switch (label) {
      case 'AC':
        onClear();
      case '⌫':
        onBackspace();
      case '%':
        onPercent();
      case '±':
        onToggleSign();
      case '.':
        onDecimal();
      case '=':
        onEquals();
      case '÷':
        onOperator('/');
      case '×':
        onOperator('x');
      case '−':
        onOperator('-');
      case '+':
        onOperator('+');
    }
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.onPressed,
    required this.selected,
  });
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isOperator = const ['÷', '×', '−', '+', '='].contains(label);
    final isUtility = const ['AC', '⌫', '%', '±'].contains(label);
    final background = selected
        ? Colors.white
        : isOperator
        ? const Color(0xFF6C63FF)
        : isUtility
        ? const Color(0xFF363842)
        : const Color(0xFF24252D);
    final foreground = selected
        ? const Color(0xFF5148D9)
        : isUtility
        ? const Color(0xFFE4E4E8)
        : Colors.white;
    return Semantics(
      button: true,
      label: _semanticLabel(label),
      child: SizedBox.expand(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: Key('button-$label'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, color: foreground, size: 25)
                  : Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: isUtility ? 22 : 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(String value) => switch (value) {
    'AC' => 'Clear',
    '⌫' => 'Backspace',
    '÷' => 'Divide',
    '×' => 'Multiply',
    '−' => 'Subtract',
    '+' => 'Add',
    '±' => 'Change sign',
    '%' => 'Percent',
    '=' => 'Equals',
    _ => value,
  };
}
