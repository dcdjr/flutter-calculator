import 'package:expressions/expressions.dart';

/// Independent keypad state and expression evaluation.
class Calculator {
  static const maxLength = 300;
  final List<String> _tokens = [];
  bool _evaluated = false;
  String? _result;
  String? error;
  String get expression => _tokens.join(' ');
  String get display =>
      _tokens.isEmpty ? '0' : '$expression${_evaluated ? ' = $_result' : ''}';
  bool _isOperator(String token) => const ['+', '-', '*', '/'].contains(token);

  void clear() {
    _tokens.clear();
    _evaluated = false;
    _result = null;
    error = null;
  }

  void press(String key) {
    if (key == 'C') {
      clear();
      return;
    }
    error = null;
    if (key == '=') {
      _calculate();
      return;
    }
    if (key == 'x²') {
      _square();
      return;
    }
    if (key == 'DEL') {
      _evaluated = false;
      _result = null;
      if (_tokens.isNotEmpty) {
        final last = _tokens.removeLast();
        if (last.length > 1) _tokens.add(last.substring(0, last.length - 1));
      }
      return;
    }
    if (!_isOperator(key) && !RegExp(r'^[0-9.]$').hasMatch(key)) {
      error = 'Use the calculator keys.';
      return;
    }
    if (_evaluated) {
      final previous = _result!;
      clear();
      if (_isOperator(key)) _tokens.add(previous);
    }
    if (expression.length >= maxLength) {
      error = 'Expression too long. Calculate or delete some digits.';
      return;
    }
    if (_isOperator(key)) {
      if (_tokens.isEmpty) {
        if (key == '-') {
          _tokens.add('-');
        } else {
          error = 'Enter a number first.';
        }
      } else if (_isOperator(_tokens.last)) {
        if (key == '-' && _tokens.length.isEven) {
          _tokens.add('-');
        } else {
          error = 'Enter a number after the operator.';
        }
      } else {
        _tokens.add(key);
      }
      return;
    }
    if (_tokens.isEmpty || _isOperator(_tokens.last)) {
      if (_tokens.isNotEmpty && _tokens.last == '-' && _tokens.length.isOdd) {
        _tokens[_tokens.length - 1] = key == '.' ? '-0.' : '-$key';
      } else {
        _tokens.add(key == '.' ? '0.' : key);
      }
    } else {
      final last = _tokens.last;
      if (key == '.' && last.contains('.')) {
        error = 'A number can only have one decimal point.';
      } else if ((last == '0' || last == '-0') && key != '.') {
        _tokens[_tokens.length - 1] = last == '-0' ? '-$key' : key;
      } else {
        _tokens[_tokens.length - 1] += key;
      }
    }
  }

  void _calculate() {
    if (_tokens.isEmpty || _evaluated) return;
    if (_isOperator(_tokens.last)) {
      error = 'Finish the expression with a number.';
      return;
    }
    try {
      // Every divisor is a numeric operand; this keypad has no parentheses.
      for (var i = 0; i < _tokens.length; i++) {
        if (_tokens[i] == '/' && double.parse(_tokens[i + 1]) == 0) {
          error = 'Cannot divide by zero.';
          return;
        }
      }
      // Floating-point operands avoid native integer overflow.
      final source = _tokens
          .map((t) => _isOperator(t) ? t : double.parse(t).toString())
          .join(' ');
      final value = const ExpressionEvaluator().eval(
        Expression.parse(source),
        {},
      );
      if (value is! num || !value.isFinite) {
        error = 'Result is too large. Try smaller numbers.';
        return;
      }
      // Limit displayed precision to keep decimal arithmetic readable.
      final rounded = double.parse(value.toStringAsPrecision(12));
      _result = rounded == 0
          ? '0'
          : rounded.toString().replaceFirst(RegExp(r'\.0$'), '');
      _evaluated = true;
    } on Object {
      error = 'Unable to calculate. Check the expression or press C.';
    }
  }

  void _square() {
    if (_evaluated) {
      _tokens
        ..clear()
        ..add(_result!);
      _evaluated = false;
      _result = null;
    }
    if (_tokens.isEmpty || _isOperator(_tokens.last)) {
      error = 'Enter a number first.';
      return;
    }
    try {
      final value = double.parse(_tokens.last);
      final squared = value * value;
      if (!squared.isFinite) {
        error = 'Result is too large. Try a smaller number.';
        return;
      }
      final rounded = double.parse(squared.toStringAsPrecision(12));
      _tokens[_tokens.length - 1] = rounded == 0
          ? '0'
          : rounded.toString().replaceFirst(RegExp(r'\.0$'), '');
    } on Object {
      error = 'Unable to square this number.';
    }
  }
}
