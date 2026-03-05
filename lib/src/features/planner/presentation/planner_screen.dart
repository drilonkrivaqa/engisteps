import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/gpa_repository.dart';
import '../data/planner_repository.dart';

class EngineeringPlannerScreen extends ConsumerStatefulWidget {
  const EngineeringPlannerScreen({super.key});

  @override
  ConsumerState<EngineeringPlannerScreen> createState() =>
      _EngineeringPlannerScreenState();
}

class _EngineeringPlannerScreenState
    extends ConsumerState<EngineeringPlannerScreen> {
  final _taskTitleController = TextEditingController();
  final _taskCourseController = TextEditingController();
  DateTime _taskDueDate = DateTime.now().add(const Duration(days: 7));
  PlannerPriority _taskPriority = PlannerPriority.medium;

  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController(text: '3');
  final _targetGpaController = TextEditingController(text: '3.5');
  final _remainingCreditsController = TextEditingController(text: '30');
  double _selectedGradePoint = 4.0;

  final _formulaSearchController = TextEditingController();

  Timer? _timer;
  int _sessionMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _running = false;

  static const _gradeScale = <MapEntry<String, double>>[
    MapEntry('A (4.0)', 4.0),
    MapEntry('A- (3.7)', 3.7),
    MapEntry('B+ (3.3)', 3.3),
    MapEntry('B (3.0)', 3.0),
    MapEntry('B- (2.7)', 2.7),
    MapEntry('C+ (2.3)', 2.3),
    MapEntry('C (2.0)', 2.0),
    MapEntry('D (1.0)', 1.0),
    MapEntry('F (0.0)', 0.0),
  ];

  static const _formulas = <_FormulaItem>[
    _FormulaItem(
      category: 'Circuits',
      title: 'Ohm law',
      equation: 'V = I * R',
      usage: 'Voltage, current, resistance relation.',
    ),
    _FormulaItem(
      category: 'Circuits',
      title: 'RC cutoff',
      equation: 'fc = 1 / (2 * pi * R * C)',
      usage: 'First-order filter cutoff frequency.',
    ),
    _FormulaItem(
      category: 'Math',
      title: 'Quadratic roots',
      equation: 'x = (-b +/- sqrt(b^2 - 4ac)) / (2a)',
      usage: 'Second-order equations.',
    ),
    _FormulaItem(
      category: 'Mechanics',
      title: 'Newton second law',
      equation: 'F = m * a',
      usage: 'Relates force and acceleration.',
    ),
    _FormulaItem(
      category: 'Mechanics',
      title: 'Kinetic energy',
      equation: 'Ek = 0.5 * m * v^2',
      usage: 'Energy of moving body.',
    ),
    _FormulaItem(
      category: 'Materials',
      title: 'Stress',
      equation: 'sigma = F / A',
      usage: 'Normal stress in member.',
    ),
    _FormulaItem(
      category: 'Materials',
      title: 'Strain',
      equation: 'epsilon = DeltaL / L0',
      usage: 'Relative deformation.',
    ),
    _FormulaItem(
      category: 'Fluids',
      title: 'Reynolds number',
      equation: 'Re = rho * v * D / mu',
      usage: 'Flow regime estimate.',
    ),
    _FormulaItem(
      category: 'Fluids',
      title: 'Continuity',
      equation: 'A1 * v1 = A2 * v2',
      usage: 'Steady incompressible flow.',
    ),
    _FormulaItem(
      category: 'Thermo',
      title: 'Ideal gas law',
      equation: 'P * V = n * R * T',
      usage: 'State variable relation.',
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _taskTitleController.dispose();
    _taskCourseController.dispose();
    _courseNameController.dispose();
    _creditsController.dispose();
    _targetGpaController.dispose();
    _remainingCreditsController.dispose();
    _formulaSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(plannerProvider);
    final courses = ref.watch(gpaProvider);

    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _header(context, tasks, courses),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Tasks'),
                    Tab(text: 'GPA'),
                    Tab(text: 'Focus'),
                    Tab(text: 'Formula'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlannerTab(context, tasks),
                  _buildGpaTab(context, courses),
                  _buildFocusTab(context),
                  _buildFormulaTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    List<PlannerTask> tasks,
    List<CourseGrade> courses,
  ) {
    final remainingTasks = tasks.where((task) => !task.done).length;
    final gpa = _currentGpa(courses);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF10263E), Color(0xFF2E577F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Control Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'One place for deadlines, GPA planning, focus sessions, and core formulas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile(context, label: 'Open tasks', value: '$remainingTasks'),
              const SizedBox(width: 10),
              _statTile(
                context,
                label: 'Current GPA',
                value: courses.isEmpty ? '-' : gpa.toStringAsFixed(2),
              ),
              const SizedBox(width: 10),
              _statTile(context, label: 'Timer', value: '${_sessionMinutes}m'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerTab(BuildContext context, List<PlannerTask> tasks) {
    final pending = tasks.where((task) => !task.done).length;
    final completed = tasks.length - pending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add Task',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _taskTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'Lab report, assignment, quiz prep...',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _taskCourseController,
                  decoration: const InputDecoration(
                    labelText: 'Course (optional)',
                    hintText: 'Signals, Thermodynamics, Materials...',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _priorityChip(PlannerPriority.low),
                    _priorityChip(PlannerPriority.medium),
                    _priorityChip(PlannerPriority.high),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _pickTaskDate,
                      icon: const Icon(Icons.event),
                      label: Text(
                        DateFormat('EEE, MMM d').format(_taskDueDate),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _taskDueDate = DateTime.now());
                      },
                      child: const Text('Today'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(
                          () => _taskDueDate = DateTime.now().add(
                            const Duration(days: 1),
                          ),
                        );
                      },
                      child: const Text('Tomorrow'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(
                          () => _taskDueDate = DateTime.now().add(
                            const Duration(days: 7),
                          ),
                        );
                      },
                      child: const Text('+7 days'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Add task'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusChip(context, 'Total ${tasks.length}'),
            _statusChip(context, 'Pending $pending'),
            _statusChip(context, 'Completed $completed'),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No tasks yet. Add your first assignment above.'),
            ),
          )
        else
          ...tasks.map((task) => _taskTile(context, task)).toList(),
        if (completed > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(plannerProvider.notifier).clearCompleted(),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear completed'),
            ),
          ),
      ],
    );
  }

  Widget _priorityChip(PlannerPriority priority) {
    final selected = _taskPriority == priority;
    return ChoiceChip(
      selected: selected,
      label: Text(priority.label),
      onSelected: (_) => setState(() => _taskPriority = priority),
    );
  }

  Widget _statusChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(label),
    );
  }

  Widget _taskTile(BuildContext context, PlannerTask task) {
    final dueLabel = DateFormat('MMM d').format(task.dueDate);
    final overdue =
        !task.done &&
        task.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.done,
          onChanged: (_) => ref.read(plannerProvider.notifier).toggle(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${task.course.isEmpty ? 'General' : task.course} | Due $dueLabel | ${task.priority.label}${overdue ? ' | Overdue' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(plannerProvider.notifier).remove(task.id),
        ),
      ),
    );
  }

  Widget _buildGpaTab(BuildContext context, List<CourseGrade> courses) {
    final totalCredits = courses.fold<double>(
      0,
      (total, course) => total + course.credits,
    );
    final gpa = _currentGpa(courses);
    final requiredGrade = _requiredAverageForTarget(courses);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current GPA',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  courses.isEmpty ? '-' : gpa.toStringAsFixed(3),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Tracked credits: ${totalCredits.toStringAsFixed(1)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Course Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course name',
                    prefixIcon: Icon(Icons.book),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _creditsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<double>(
                  value: _selectedGradePoint,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    prefixIcon: Icon(Icons.grade),
                  ),
                  items: _gradeScale
                      .map(
                        (grade) => DropdownMenuItem<double>(
                          value: grade.value,
                          child: Text(grade.key),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedGradePoint = value);
                  },
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addCourse,
                  icon: const Icon(Icons.add),
                  label: const Text('Add course'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Planner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _targetGpaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Target GPA'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remainingCreditsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Remaining credits',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Text(
                  requiredGrade,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No courses tracked yet.'),
            ),
          )
        else
          ...courses.map((course) {
            return Card(
              child: ListTile(
                title: Text(course.name),
                subtitle: Text(
                  '${course.credits.toStringAsFixed(1)} credits | Grade point ${course.gradePoint.toStringAsFixed(1)}',
                ),
                trailing: IconButton(
                  onPressed: () =>
                      ref.read(gpaProvider.notifier).remove(course.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            );
          }),
        if (courses.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ref.read(gpaProvider.notifier).clear(),
              child: const Text('Clear all courses'),
            ),
          ),
      ],
    );
  }

  Widget _buildFocusTab(BuildContext context) {
    final seconds = _remainingSeconds % 60;
    final minutes = _remainingSeconds ~/ 60;
    final totalSeconds = (_sessionMinutes * 60).clamp(1, 36000);
    final progress = _remainingSeconds / totalSeconds;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  'Focus Timer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                      ),
                      Center(
                        child: Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _durationChip(context, 25),
                    _durationChip(context, 45),
                    _durationChip(context, 60),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _running ? _pauseTimer : _startTimer,
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pause' : 'Start'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Tip: Do one focused block for derivations and one for calculations. Keep phone away during each block.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _durationChip(BuildContext context, int minutes) {
    final selected = _sessionMinutes == minutes;
    return ChoiceChip(
      label: Text('$minutes min'),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _sessionMinutes = minutes;
          _remainingSeconds = minutes * 60;
        });
      },
    );
  }

  Widget _buildFormulaTab(BuildContext context) {
    final query = _formulaSearchController.text.trim().toLowerCase();
    final items = _formulas.where((formula) {
      if (query.isEmpty) return true;
      return formula.category.toLowerCase().contains(query) ||
          formula.title.toLowerCase().contains(query) ||
          formula.equation.toLowerCase().contains(query) ||
          formula.usage.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
      children: [
        TextField(
          controller: _formulaSearchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search formula, topic, symbol...',
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No formula matches this search.'),
            ),
          )
        else
          ...items.map(
            (formula) => Card(
              child: ListTile(
                title: Text(formula.title),
                subtitle: Text(
                  '${formula.category}\n${formula.equation}\n${formula.usage}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${formula.title}\n${formula.equation}\n${formula.usage}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formula copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickTaskDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _taskDueDate,
    );

    if (selected == null) return;
    setState(() => _taskDueDate = selected);
  }

  Future<void> _addTask() async {
    final title = _taskTitleController.text.trim();
    final course = _taskCourseController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    await ref
        .read(plannerProvider.notifier)
        .add(
          title: title,
          course: course,
          dueDate: _taskDueDate,
          priority: _taskPriority,
        );

    if (!mounted) return;
    setState(() {
      _taskTitleController.clear();
      _taskCourseController.clear();
      _taskPriority = PlannerPriority.medium;
      _taskDueDate = DateTime.now().add(const Duration(days: 7));
    });
  }

  Future<void> _addCourse() async {
    final course = _courseNameController.text.trim();
    final credits = double.tryParse(
      _creditsController.text.replaceAll(',', '.').trim(),
    );

    if (course.isEmpty || credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid course and credit values.')),
      );
      return;
    }

    await ref
        .read(gpaProvider.notifier)
        .add(name: course, credits: credits, gradePoint: _selectedGradePoint);

    if (!mounted) return;
    setState(() {
      _courseNameController.clear();
      _creditsController.text = '3';
      _selectedGradePoint = 4.0;
    });
  }

  double _currentGpa(List<CourseGrade> courses) {
    final totalCredits = courses.fold<double>(
      0,
      (total, course) => total + course.credits,
    );

    if (totalCredits <= 0) return 0;

    final qualityPoints = courses.fold<double>(
      0,
      (total, course) => total + (course.credits * course.gradePoint),
    );

    return qualityPoints / totalCredits;
  }

  String _requiredAverageForTarget(List<CourseGrade> courses) {
    final target = double.tryParse(
      _targetGpaController.text.replaceAll(',', '.').trim(),
    );
    final remaining = double.tryParse(
      _remainingCreditsController.text.replaceAll(',', '.').trim(),
    );

    if (target == null || remaining == null || remaining <= 0) {
      return 'Set target GPA and remaining credits to compute requirement.';
    }

    final totalCredits = courses.fold<double>(
      0,
      (total, course) => total + course.credits,
    );
    final qualityPoints = courses.fold<double>(
      0,
      (total, course) => total + (course.credits * course.gradePoint),
    );

    final required =
        ((target * (totalCredits + remaining)) - qualityPoints) / remaining;

    if (required > 4.0) {
      return 'Required average ${required.toStringAsFixed(2)} is above 4.0 (not feasible on this scale).';
    }
    if (required < 0) {
      return 'Target already secured with current performance.';
    }

    return 'Needed average on remaining credits: ${required.toStringAsFixed(2)} / 4.0';
  }

  void _startTimer() {
    if (_running) return;

    setState(() => _running = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _running = false;
          _remainingSeconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session complete. Take a short break.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _sessionMinutes * 60;
    });
  }
}

class _FormulaItem {
  const _FormulaItem({
    required this.category,
    required this.title,
    required this.equation,
    required this.usage,
  });

  final String category;
  final String title;
  final String equation;
  final String usage;
}
