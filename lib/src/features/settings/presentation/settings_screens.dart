import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          SectionCard(
            title: 'Appearance',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.darkMode,
                  onChanged: controller.setDarkMode,
                  title: const Text('Dark mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Computation',
            subtitle: 'Control how results are displayed.',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.scientificNotation,
                  onChanged: controller.setScientificNotation,
                  title: const Text('Scientific notation'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: settings.decimalPrecision,
                  decoration: const InputDecoration(
                    labelText: 'Decimal precision',
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  items: const [0, 1, 2, 3, 4, 5, 6]
                      .map((p) => DropdownMenuItem(value: p, child: Text('$p')))
                      .toList(),
                  onChanged: (v) => controller.setPrecision(v ?? 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Mode',
            subtitle: 'Professor mode unlocks Classroom features.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.professorMode,
              onChanged: controller.setProfessorMode,
              title: const Text('Professor mode'),
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'About',
            subtitle: 'EngiSteps is offline-first and fast.',
            child: Text('Next: add more tools + export/share templates.'),
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Account',
    body: SectionCard(title: 'Account', child: Text('Account system not implemented (offline app).')),
  );
}

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Preferences',
    body: SectionCard(title: 'Preferences', child: Text('Add preferences here later.')),
  );
}

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Units',
    body: SectionCard(title: 'Units', child: Text('Unit conversion engine can be added next.')),
  );
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Offline',
    body: SectionCard(title: 'Offline', child: Text('EngiSteps already works offline.')),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'About',
    body: SectionCard(title: 'About EngiSteps', child: Text('Engineering toolkit for students & professors.')),
  );
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Legal',
    body: SectionCard(title: 'Legal', child: Text('Add licenses and disclaimers here.')),
  );
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Feedback',
    body: SectionCard(title: 'Feedback', child: Text('Add email/issue link later.')),
  );
}