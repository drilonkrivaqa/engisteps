import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const EngiStepsApp());
}

class EngiStepsApp extends StatelessWidget {
  const EngiStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EngiSteps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5F6368),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE3E6EB)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EngiSteps')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HomeTile(
              title: 'Binary',
              subtitle: 'Base complements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BinaryToolsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _HomeTile(
              title: 'Matrices',
              subtitle: 'Determinants',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatrixToolsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _HomeTile(
              title: 'Complex',
              subtitle: 'Rectangular to polar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplexToolsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        height: 110,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BinaryToolsScreen extends StatelessWidget {
  const BinaryToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Binary Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _ToolTile(
          label: 'Complements',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComplementsPage()),
          ),
        ),
      ),
    );
  }
}

class MatrixToolsScreen extends StatelessWidget {
  const MatrixToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ToolTile(
              label: 'Determinant 2x2',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Determinant2x2Page()),
              ),
            ),
            const SizedBox(height: 12),
            _ToolTile(
              label: 'Determinant 3x3 (Sarrus)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Determinant3x3Page()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplexToolsScreen extends StatelessWidget {
  const ComplexToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complex Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _ToolTile(
          label: 'a + bi to polar',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComplexToPolarPage()),
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        height: 88,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComplementsPage extends StatefulWidget {
  const ComplementsPage({super.key});

  @override
  State<ComplementsPage> createState() => _ComplementsPageState();
}

class _ComplementsPageState extends State<ComplementsPage> {
  final _baseCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _kCtrl = TextEditingController();

  String _given = '';
  List<String> _steps = [];
  String _finalAnswer = '';

  static const _digits = '0123456789ABCDEF';

  @override
  void dispose() {
    _baseCtrl.dispose();
    _numberCtrl.dispose();
    _kCtrl.dispose();
    super.dispose();
  }

  void _fillExample1() {
    setState(() {
      _baseCtrl.text = '2';
      _numberCtrl.text = '101001';
      _kCtrl.text = '';
    });
  }

  void _fillExample2() {
    setState(() {
      _baseCtrl.text = '16';
      _numberCtrl.text = '3AF';
      _kCtrl.text = '4';
    });
  }

  int _charToValue(String c) => _digits.indexOf(c);

  String _valueToChar(int v) => _digits[v];

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _reset() {
    setState(() {
      _baseCtrl.clear();
      _numberCtrl.clear();
      _kCtrl.clear();
      _given = '';
      _steps = [];
      _finalAnswer = '';
    });
  }

  void _copyResult() {
    if (_finalAnswer.isEmpty && _steps.isEmpty) {
      _showError('No result to copy yet.');
      return;
    }
    final text = 'Given: $_given\n\nSteps:\n${_steps.join('\n')}\n\nFinal Answer:\n$_finalAnswer';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard.')),
    );
  }

  void _solve() {
    final base = int.tryParse(_baseCtrl.text.trim());
    if (base == null || base < 2 || base > 16) {
      _showError('Base B must be an integer from 2 to 16.');
      return;
    }

    var number = _numberCtrl.text.trim().toUpperCase();
    if (number.isEmpty) {
      _showError('Please enter number N.');
      return;
    }

    for (final ch in number.split('')) {
      final value = _charToValue(ch);
      if (value < 0 || value >= base) {
        _showError('Digit "$ch" is invalid for base $base.');
        return;
      }
    }

    int k = number.length;
    if (_kCtrl.text.trim().isNotEmpty) {
      final parsedK = int.tryParse(_kCtrl.text.trim());
      if (parsedK == null || parsedK <= 0) {
        _showError('k must be a positive integer.');
        return;
      }
      if (parsedK < number.length) {
        _showError('k cannot be smaller than the length of N.');
        return;
      }
      k = parsedK;
    }

    number = number.padLeft(k, '0');
    final steps = <String>[];
    steps.add('1) Normalize number to width k = $k: N = $number');

    final bMinus1 = StringBuffer();
    steps.add('2) Compute (B-1) complement digit by digit (B-1 = ${base - 1}):');
    for (var i = 0; i < number.length; i++) {
      final dChar = number[i];
      final d = _charToValue(dChar);
      final cVal = (base - 1) - d;
      final cChar = _valueToChar(cVal);
      bMinus1.write(cChar);
      steps.add('   ${i + 1}. $dChar ($d) -> ${base - 1} - $d = $cVal ($cChar)');
    }
    final bMinus1Comp = bMinus1.toString();
    steps.add('   (B-1) complement = $bMinus1Comp');

    steps.add('3) Compute B\'s complement = (B-1) complement + 1 (base $base):');
    final chars = bMinus1Comp.split('');
    int carry = 1;
    for (var i = chars.length - 1; i >= 0; i--) {
      final oldVal = _charToValue(chars[i]);
      final sum = oldVal + carry;
      final newVal = sum % base;
      carry = sum ~/ base;
      final newChar = _valueToChar(newVal);
      steps.add(
        '   pos ${i + 1}: $oldVal + ${sum - oldVal} = $sum -> write $newVal ($newChar), carry $carry',
      );
      chars[i] = newChar;
    }
    final bComp = chars.join();
    steps.add('   B\'s complement (fixed $k digits) = $bComp');
    if (carry > 0) {
      steps.add('   Overflow carry $carry is discarded for fixed width representation.');
    }

    setState(() {
      _given = 'Base B = $base, N = $number, k = $k';
      _steps = steps;
      _finalAnswer = '(B-1) complement: $bMinus1Comp\nB\'s complement: $bComp';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(
              child: Column(
                children: [
                  TextField(
                    controller: _baseCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base B (2..16)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numberCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Number N'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _kCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Optional width k',
                      hintText: 'Leave empty to use length of N',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _fillExample1,
                          child: const Text('Example 1'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _fillExample2,
                          child: const Text('Example 2'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buttonRow(onSolve: _solve, onReset: _reset, onCopy: _copyResult),
            const SizedBox(height: 16),
            _resultsSection(given: _given, steps: _steps, finalAnswer: _finalAnswer),
          ],
        ),
      ),
    );
  }
}

class Determinant2x2Page extends StatefulWidget {
  const Determinant2x2Page({super.key});

  @override
  State<Determinant2x2Page> createState() => _Determinant2x2PageState();
}

class _Determinant2x2PageState extends State<Determinant2x2Page> {
  final List<TextEditingController> _ctrls =
      List.generate(4, (_) => TextEditingController());

  String _given = '';
  List<String> _steps = [];
  String _finalAnswer = '';

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<double>? _readValues() {
    final values = <double>[];
    for (final c in _ctrls) {
      final v = double.tryParse(c.text.trim());
      if (v == null) return null;
      values.add(v);
    }
    return values;
  }

  void _error(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _solve() {
    final vals = _readValues();
    if (vals == null) {
      _error('Please fill all matrix cells with valid numbers.');
      return;
    }
    final a = vals[0], b = vals[1], c = vals[2], d = vals[3];
    final ad = a * d;
    final bc = b * c;
    final det = ad - bc;

    setState(() {
      _given = 'A = [[$a, $b], [$c, $d]]';
      _steps = [
        '1) Formula: det(A) = ad - bc',
        '2) ad = $a × $d = $ad',
        '3) bc = $b × $c = $bc',
        '4) det(A) = $ad - $bc = $det',
      ];
      _finalAnswer = 'det(A) = $det';
    });
  }

  void _reset() {
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() {
      _given = '';
      _steps = [];
      _finalAnswer = '';
    });
  }

  void _copyResult() {
    if (_finalAnswer.isEmpty) {
      _error('No result to copy yet.');
      return;
    }
    Clipboard.setData(
      ClipboardData(
        text: 'Given: $_given\n\nSteps:\n${_steps.join('\n')}\n\nFinal Answer:\n$_finalAnswer',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Determinant 2x2')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(
              child: _matrixGrid(2, 2, _ctrls),
            ),
            const SizedBox(height: 12),
            _buttonRow(onSolve: _solve, onReset: _reset, onCopy: _copyResult),
            const SizedBox(height: 16),
            _resultsSection(given: _given, steps: _steps, finalAnswer: _finalAnswer),
          ],
        ),
      ),
    );
  }
}

class Determinant3x3Page extends StatefulWidget {
  const Determinant3x3Page({super.key});

  @override
  State<Determinant3x3Page> createState() => _Determinant3x3PageState();
}

class _Determinant3x3PageState extends State<Determinant3x3Page> {
  final List<TextEditingController> _ctrls =
      List.generate(9, (_) => TextEditingController());

  String _given = '';
  List<String> _steps = [];
  String _finalAnswer = '';

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  List<double>? _readValues() {
    final values = <double>[];
    for (final c in _ctrls) {
      final v = double.tryParse(c.text.trim());
      if (v == null) return null;
      values.add(v);
    }
    return values;
  }

  void _solve() {
    final v = _readValues();
    if (v == null) {
      _error('Please fill all matrix cells with valid numbers.');
      return;
    }
    final a = v[0], b = v[1], c = v[2];
    final d = v[3], e = v[4], f = v[5];
    final g = v[6], h = v[7], i = v[8];

    final p1 = a * e * i;
    final p2 = b * f * g;
    final p3 = c * d * h;
    final n1 = c * e * g;
    final n2 = b * d * i;
    final n3 = a * f * h;
    final det = (p1 + p2 + p3) - (n1 + n2 + n3);

    setState(() {
      _given = 'A = [[$a, $b, $c], [$d, $e, $f], [$g, $h, $i]]';
      _steps = [
        '1) Sarrus: det(A) = (aei + bfg + cdh) - (ceg + bdi + afh)',
        '2) Positive diagonals: aei=$p1, bfg=$p2, cdh=$p3',
        '3) Negative diagonals: ceg=$n1, bdi=$n2, afh=$n3',
        '4) det(A) = (${p1 + p2 + p3}) - (${n1 + n2 + n3}) = $det',
      ];
      _finalAnswer = 'det(A) = $det';
    });
  }

  void _reset() {
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() {
      _given = '';
      _steps = [];
      _finalAnswer = '';
    });
  }

  void _copyResult() {
    if (_finalAnswer.isEmpty) {
      _error('No result to copy yet.');
      return;
    }
    Clipboard.setData(
      ClipboardData(
        text: 'Given: $_given\n\nSteps:\n${_steps.join('\n')}\n\nFinal Answer:\n$_finalAnswer',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Determinant 3x3 (Sarrus)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(child: _matrixGrid(3, 3, _ctrls)),
            const SizedBox(height: 12),
            _buttonRow(onSolve: _solve, onReset: _reset, onCopy: _copyResult),
            const SizedBox(height: 16),
            _resultsSection(given: _given, steps: _steps, finalAnswer: _finalAnswer),
          ],
        ),
      ),
    );
  }
}

class ComplexToPolarPage extends StatefulWidget {
  const ComplexToPolarPage({super.key});

  @override
  State<ComplexToPolarPage> createState() => _ComplexToPolarPageState();
}

class _ComplexToPolarPageState extends State<ComplexToPolarPage> {
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();

  String _given = '';
  List<String> _steps = [];
  String _finalAnswer = '';

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  void _error(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _solve() {
    final a = double.tryParse(_aCtrl.text.trim());
    final b = double.tryParse(_bCtrl.text.trim());
    if (a == null || b == null) {
      _error('Please enter valid numbers for a and b.');
      return;
    }

    final rSquared = (a * a) + (b * b);
    final r = math.sqrt(rSquared);
    final thetaRad = math.atan2(b, a);
    final thetaDeg = thetaRad * 180 / math.pi;

    setState(() {
      _given = 'z = $a + ${b}i';
      _steps = [
        '1) r = sqrt(a² + b²)',
        '2) r = sqrt(($a)² + ($b)²) = sqrt($rSquared) = $r',
        '3) θ = atan2(b, a)',
        '4) θ = atan2($b, $a) = $thetaRad rad',
        '5) θ(deg) = θ(rad) × 180/π = $thetaDeg°',
      ];
      _finalAnswer = 'Polar form: r = $r, θ = $thetaRad rad ($thetaDeg°)';
    });
  }

  void _reset() {
    _aCtrl.clear();
    _bCtrl.clear();
    setState(() {
      _given = '';
      _steps = [];
      _finalAnswer = '';
    });
  }

  void _copyResult() {
    if (_finalAnswer.isEmpty) {
      _error('No result to copy yet.');
      return;
    }
    Clipboard.setData(
      ClipboardData(
        text: 'Given: $_given\n\nSteps:\n${_steps.join('\n')}\n\nFinal Answer:\n$_finalAnswer',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('a + bi to polar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(
              child: Column(
                children: [
                  TextField(
                    controller: _aCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'a'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'b'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buttonRow(onSolve: _solve, onReset: _reset, onCopy: _copyResult),
            const SizedBox(height: 16),
            _resultsSection(given: _given, steps: _steps, finalAnswer: _finalAnswer),
          ],
        ),
      ),
    );
  }
}

Widget _inputCard({required Widget child}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}

Widget _buttonRow({
  required VoidCallback onSolve,
  required VoidCallback onReset,
  required VoidCallback onCopy,
}) {
  return Row(
    children: [
      Expanded(child: FilledButton(onPressed: onSolve, child: const Text('Solve'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(onPressed: onReset, child: const Text('Reset'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(onPressed: onCopy, child: const Text('Copy Result'))),
    ],
  );
}

Widget _resultsSection({
  required String given,
  required List<String> steps,
  required String finalAnswer,
}) {
  final hasData = given.isNotEmpty || steps.isNotEmpty || finalAnswer.isNotEmpty;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (!hasData)
            const Text('No result yet. Fill inputs and tap Solve.')
          else ...[
            Text('Given: $given'),
            const SizedBox(height: 10),
            const Text('Steps:'),
            const SizedBox(height: 6),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(step),
              ),
            const SizedBox(height: 10),
            Text(
              'Final Answer:\n$finalAnswer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _matrixGrid(int rows, int cols, List<TextEditingController> ctrls) {
  return Column(
    children: List.generate(rows, (r) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: List.generate(cols, (c) {
            final index = r * cols + c;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: c == cols - 1 ? 0 : 8),
                child: TextField(
                  controller: ctrls[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }),
  );
}
