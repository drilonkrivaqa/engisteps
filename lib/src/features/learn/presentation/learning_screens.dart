import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/smart_number_parser.dart';
import '../data/learning_repository.dart';
import '../domain/circuit_course.dart';
import '../domain/circuit_experiment.dart';

export 'student_home_screen.dart' show LearnScreen;

class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.topicId});
  final String topicId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = circuitTopics.where((t) => t.id == topicId);
    if (matches.isEmpty) return const _Missing();
    final topic = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        leading: BackButton(onPressed: () => _backToLearning(context)),
      ),
      body: ref
          .watch(learningProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(learningProvider),
                child: const Text('Retry loading progress'),
              ),
            ),
            data: (progress) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Panel(
                      title: topic.outcome,
                      children: [
                        Text(topic.concept),
                        const SizedBox(height: 12),
                        const Text(
                          'Assumptions: ideal resistors and wires, steady DC. Voltage dividers have no output load.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final p in topic.problems)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            progress.attempt(p.id).completed
                                ? Icons.check_circle_outline
                                : p.guided
                                ? Icons.school_outlined
                                : Icons.edit_outlined,
                          ),
                          title: Text(p.title),
                          subtitle: Text(
                            p.guided
                                ? 'Guided example'
                                : progress.attempt(p.id).independent
                                ? 'Solved without help'
                                : progress.attempt(p.id).completed
                                ? 'Completed with help · try again'
                                : 'Independent practice',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/learn/problem/${p.id}'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const _Panel(
                      title: 'Built on standard circuit relationships',
                      children: [
                        Text(
                          'Original exercises using series resistance, parallel resistance and the unloaded voltage divider relationship. Reference: OpenStax, University Physics Volume 2, section 10.2.',
                        ),
                        SizedBox(height: 8),
                        SelectableText(
                          'https://openstax.org/books/university-physics-volume-2/pages/10-2-resistors-in-series-and-parallel',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class ProblemScreen extends ConsumerStatefulWidget {
  const ProblemScreen({super.key, required this.problemId});
  final String problemId;
  @override
  ConsumerState<ProblemScreen> createState() => _ProblemState();
}

class _ProblemState extends ConsumerState<ProblemScreen> {
  final _answer = TextEditingController();
  final _stepKey = GlobalKey();
  bool _busy = false;
  String? _feedback;
  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save(LearningAttempt attempt, {String? feedback}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(learningProvider.notifier).save(widget.problemId, attempt);
      if (mounted) setState(() => _feedback = feedback);
      if (mounted && (attempt.methodDone || attempt.completed)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final stepContext = _stepKey.currentContext;
          if (mounted && stepContext != null) {
            Scrollable.ensureVisible(
              stepContext,
              duration: const Duration(milliseconds: 250),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _feedback = 'Your progress could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = findProblem(widget.problemId);
    if (p == null) return const _Missing();
    return Scaffold(
      appBar: AppBar(
        title: Text(p.topic.title),
        leading: BackButton(onPressed: () => _backToLearning(context)),
      ),
      body: ref
          .watch(learningProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(learningProvider),
                child: const Text('Retry loading progress'),
              ),
            ),
            data: (progress) => _body(p, progress),
          ),
    );
  }

  Widget _body(CircuitProblem p, LearningProgress progress) {
    final attempt = progress.attempt(p.id);
    final colors = Theme.of(context).colorScheme;
    final index = circuitProblems.indexOf(p);
    final next = index + 1 < circuitProblems.length
        ? circuitProblems[index + 1]
        : null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${p.guided ? 'GUIDED EXAMPLE' : 'PRACTICE'}  /  ${attempt.completed
                  ? 'COMPLETE'
                  : attempt.methodDone
                  ? 'STEP 2 OF 2'
                  : 'STEP 1 OF 2'}',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(p.prompt, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            CircuitDiagram(problem: p),
            const SizedBox(height: 16),
            if (p.guided) ...[
              Card(
                child: ExpansionTile(
                  title: const Text('How does this circuit work?'),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Text(p.topic.concept),
                    const SizedBox(height: 8),
                    Text('Method: ${p.methods[p.method]}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!attempt.completed) ...[
              _Panel(
                key: _stepKey,
                title: attempt.methodDone
                    ? '2. Work out the answer'
                    : '1. Choose your method',
                children: [
                  if (!attempt.methodDone) ...[
                    const Text(
                      'Which relationship matches the unknown and the circuit?',
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < p.methods.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _save(
                                  attempt.copyWith(
                                    methodDone: i == p.method,
                                    helped: attempt.helped || i != p.method,
                                  ),
                                  feedback: p.methodFeedback(i),
                                ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(p.methods[i]),
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    Text(p.methods[p.method]),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answer,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: 'Answer in ${p.unit}',
                        helperText:
                            'Numbers or expressions, e.g. 220+330. Tolerance: 0.5%.',
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _check(p, attempt),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : () => _check(p, attempt),
                      child: const Text('Check answer'),
                    ),
                  ],
                  if (_feedback != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _feedback!,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (!attempt.hintShown)
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _save(
                              attempt.copyWith(helped: true, hintShown: true),
                            ),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Give me a hint'),
                    ),
                  if (attempt.hintShown) Text(p.hint),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _save(
                            attempt.copyWith(
                              helped: true,
                              completed: true,
                              independent: false,
                            ),
                          ),
                    child: const Text('Show worked solution'),
                  ),
                ],
              ),
            ] else ...[
              _Panel(
                key: _stepKey,
                title: p.guided
                    ? 'Example complete. Now try it yourself.'
                    : attempt.independent
                    ? 'Solved without help.'
                    : 'You worked through it.',
                children: [
                  Text(
                    p.working,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 12),
                  Text(p.senseCheck),
                  const SizedBox(height: 12),
                  Text(
                    p.guided
                        ? 'The next activity uses the same idea with different values.'
                        : attempt.independent
                        ? 'You selected the method and reached the answer without hints or corrections on this attempt.'
                        : 'This attempt used help or corrections. Try it again later without help to build confidence.',
                  ),
                  const SizedBox(height: 16),
                  if (next != null)
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => context.pushReplacement(
                              '/learn/problem/${next.id}',
                            ),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        next.guided
                            ? 'Next topic: ${next.topic.title}'
                            : 'Try the next problem',
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => context.go('/learn'),
                      child: const Text('See my progress'),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _answer.clear();
                                _save(const LearningAttempt());
                              },
                        child: const Text('Try again from the start'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${p.title}\n${p.prompt}\n\n${p.working}\n${p.senseCheck}\n\nMy reflection: ',
                            ),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Working copied. Add your reflection in Notes.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy working'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/notes'),
                        child: const Text('Open my notes'),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/lab',
                      extra: CircuitExperiment(
                        kind: p.topic.kind,
                        r1: p.r1,
                        r2: p.r2,
                        voltage: p.voltage,
                      ),
                    ),
                    child: const Text('Experiment with this circuit'),
                  ),
                ],
              ),
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_feedback!),
                ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Ideal components and wires. DC conditions. Divider output is unloaded.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _check(CircuitProblem p, LearningAttempt attempt) {
    if (_busy || attempt.completed) return;
    final parsed = SmartNumberParser.parse(_answer.text);
    if (parsed == null || !parsed.isFinite) {
      setState(
        () => _feedback = 'Enter a finite number or expression in ${p.unit}.',
      );
      return;
    }
    final correct = p.accepts(parsed);
    _save(
      attempt.copyWith(
        completed: correct,
        helped: attempt.helped || !correct,
        independent: correct && !attempt.helped && !p.guided,
      ),
      feedback: correct ? null : p.feedback(parsed),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

void _backToLearning(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/learn');
  }
}

class _Missing extends StatelessWidget {
  const _Missing();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Activity unavailable')),
    body: Center(
      child: FilledButton(
        onPressed: () => context.go('/learn'),
        child: const Text('Go to learning'),
      ),
    ),
  );
}

class CircuitDiagram extends StatelessWidget {
  const CircuitDiagram({super.key, required this.problem});
  final CircuitProblem problem;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${problem.topic.title}. ${problem.prompt}',
    image: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _CircuitPainter(
                problem.topic.kind,
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 8,
            children: [
              Text('R1 = ${problem.resistor(problem.r1)}'),
              Text('R2 = ${problem.resistor(problem.r2)}'),
              if (problem.topic.kind == CircuitKind.divider)
                Text('Vin = ${number(problem.voltage)} V · Vout across R2'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter(this.kind, this.color);
  final CircuitKind kind;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width < 360 ? size.width / 360 : 1.0;
    canvas.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 130 * scale) / 2,
    );
    canvas.scale(scale);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pen);
    void label(String text, double x, double y) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x, y));
    }

    void resistor(double x, double y, String text) {
      canvas.drawRect(Rect.fromLTWH(x, y - 10, 70, 20), pen);
      label(text, x + 24, y - 34);
    }

    if (kind == CircuitKind.parallel) {
      line(20, 65, 60, 65);
      line(60, 30, 60, 100);
      line(60, 30, 140, 30);
      resistor(140, 30, 'R1');
      line(210, 30, 300, 30);
      line(60, 100, 140, 100);
      resistor(140, 100, 'R2');
      line(210, 100, 300, 100);
      line(300, 30, 300, 100);
      line(300, 65, 340, 65);
    } else {
      line(20, 60, 70, 60);
      resistor(70, 60, 'R1');
      line(140, 60, 210, 60);
      resistor(210, 60, 'R2');
      line(280, 60, 340, 60);
      if (kind == CircuitKind.divider) {
        line(20, 60, 20, 77);
        line(20, 103, 20, 112);
        line(20, 112, 340, 112);
        line(340, 112, 340, 60);
        canvas.drawCircle(const Offset(20, 90), 13, pen);
        line(16, 85, 24, 85);
        line(20, 81, 20, 89);
        line(16, 96, 24, 96);
        label('Vin', 40, 88);
        line(175, 60, 175, 85);
        label('Vout +', 145, 88);
        label('−', 321, 88);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
