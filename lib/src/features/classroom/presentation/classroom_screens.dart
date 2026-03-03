import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_card.dart';

class ProfessorDashboardScreen extends StatelessWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Classroom',
      body: ListView(
        children: [
          const SectionCard(
            title: 'Professor tools (MVP)',
            subtitle: 'Build a worksheet template students can follow step-by-step.',
            child: Text('This is intentionally simple now — but useful.'),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Templates',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('Template builder'),
                  subtitle: const Text('Create a problem sheet structure'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/classroom/template-builder'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.preview_outlined),
                  title: const Text('Template preview'),
                  subtitle: const Text('See how it looks for students'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/classroom/template-preview'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share template'),
                  subtitle: const Text('Copy a shareable text format'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/classroom/share-template'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TemplateBuilderScreen extends StatefulWidget {
  const TemplateBuilderScreen({super.key});

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  final _title = TextEditingController(text: 'Lab Worksheet');
  final _objective = TextEditingController(text: 'Measure and calculate...');
  final _steps = <TextEditingController>[
    TextEditingController(text: 'Write down given values.'),
    TextEditingController(text: 'Apply the correct formula.'),
    TextEditingController(text: 'Show units and final answer.'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _objective.dispose();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Template builder',
      body: ListView(
        children: [
          SectionCard(
            title: 'Template',
            child: Column(
              children: [
                TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(
                  controller: _objective,
                  decoration: const InputDecoration(labelText: 'Objective'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Steps', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                ..._steps.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(labelText: 'Step ${e.key + 1}'),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _steps.add(TextEditingController())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add step'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved locally later (TODO).')),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TemplatePreviewScreen extends StatelessWidget {
  const TemplatePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Template preview',
      body: SectionCard(
        title: 'Student view',
        subtitle: 'This will later load saved templates.',
        child: Text(
          '1) Given:\n'
              '2) Formula:\n'
              '3) Substitute values:\n'
              '4) Compute:\n'
              '5) Final answer with units:\n',
        ),
      ),
    );
  }
}

class ShareTemplateScreen extends StatelessWidget {
  const ShareTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sample =
        'ENGISTEPS_TEMPLATE\n'
        'TITLE: Lab Worksheet\n'
        'OBJECTIVE: Measure and calculate...\n'
        'STEPS:\n'
        '- Write down given values.\n'
        '- Apply the correct formula.\n'
        '- Show units and final answer.\n';

    return AppScaffold(
      title: 'Share template',
      body: ListView(
        children: [
          SectionCard(
            title: 'Copy this text',
            subtitle: 'Send in WhatsApp/Teams. Later you can import it.',
            child: SelectableText(sample),
          ),
        ],
      ),
    );
  }
}