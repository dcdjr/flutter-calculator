import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Calculator',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF275D50)),
      scaffoldBackgroundColor: const Color(0xFFF4F3EE),
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
  final _calculator = Calculator();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  @override
  void dispose() {
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _press(String key) {
    setState(() => _calculator.press(key));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _press('=');
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyC) {
      _press('C');
    } else if (key == LogicalKeyboardKey.backspace) {
      _press('DEL');
    } else if (event.character != null &&
        RegExp(r'^[0-9.+*/=\-]$').hasMatch(event.character!)) {
      _press(event.character!);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Calculator',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF193F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A little clarity in every calculation.',
                    style: TextStyle(color: Color(0xFF58665F), fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF193F36),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ACCUMULATOR',
                          style: TextStyle(
                            color: Color(0xFFACCCB7),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: true,
                          label: 'Accumulator',
                          child: SingleChildScrollView(
                            controller: _scroll,
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              _calculator.display,
                              key: const ValueKey('display'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Multiply and divide before add and subtract',
                          style: TextStyle(
                            color: Color(0xFFACCCB7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _calculator.error ?? 'Enter an expression, then tap =',
                        style: TextStyle(
                          fontSize: 13,
                          color: _calculator.error == null
                              ? const Color(0xFF58665F)
                              : const Color(0xFFAA2929),
                        ),
                      ),
                    ),
                  ),
                  _row(['C', 'DEL', '/']),
                  _row(['7', '8', '9', '*']),
                  _row(['4', '5', '6', '-']),
                  _row(['1', '2', '3', '+']),
                  _row(['0', '.', '=']),
                  const SizedBox(height: 12),
                  const Text(
                    'Take it one number at a time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF58665F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _row(List<String> keys) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            flex: keys.length == 3 && i == 0 ? 2 : 1,
            child: _button(keys[i]),
          ),
        ],
      ],
    ),
  );
  Widget _button(String key) {
    final isOperator = ['+', '-', '*', '/'].contains(key);
    final background = key == '='
        ? const Color(0xFF275D50)
        : key == 'C'
        ? const Color(0xFFF1DDD2)
        : isOperator
        ? const Color(0xFFDCE7DE)
        : Colors.white;
    const labels = {
      'C': 'Clear',
      'DEL': 'Delete last character',
      '/': 'Divide',
      '*': 'Multiply',
      '-': 'Subtract',
      '+': 'Add',
      '=': 'Equals',
    };
    return Semantics(
      label: labels[key] ?? key,
      child: FilledButton(
        key: ValueKey('key_$key'),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: key == '=' ? Colors.white : const Color(0xFF193F36),
          minimumSize: const Size(0, 64),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        onPressed: () => _press(key),
        child: ExcludeSemantics(
          child: key == 'DEL'
              ? const Icon(Icons.backspace_outlined)
              : Text(key),
        ),
      ),
    );
  }
}
