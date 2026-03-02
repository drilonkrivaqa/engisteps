import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../settings/data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final c = ref.read(settingsControllerProvider.notifier);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          SectionCard(
            title: 'Preferences',
            child: Column(
              children: [
                SwitchListTile(
                  value: s.darkMode,
                  title: const Text('Dark mode'),
                  onChanged: c.setDarkMode,
                ),
                SwitchListTile(
                  value: s.professorMode,
                  title: const Text('Professor Mode'),
                  subtitle: const Text('Enable classroom templates and sharing.'),
                  onChanged: c.setProfessorMode,
                ),
              ],
            ),
          ),
          ...[
            ('Account', '/settings/account'),
            ('Preferences details', '/settings/preferences'),
            ('Units', '/settings/units'),
            ('Offline', '/settings/offline'),
            ('About', '/settings/about'),
            ('Legal', '/settings/legal'),
            ('Feedback', '/settings/feedback'),
          ].map(
            (item) => ListTile(
              title: Text(item.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(item.$2),
            ),
          ),
          if (s.professorMode)
            ListTile(
              title: const Text('Classroom'),
              trailing: const Icon(Icons.school_outlined),
              onTap: () => context.push('/classroom/dashboard'),
            ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AppScaffold(title: 'Account', body: Text('Guest profile data stub.'));
}

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final c = ref.read(settingsControllerProvider.notifier);
    return AppScaffold(
      title: 'Preferences',
      body: ListView(
        children: [
          const ListTile(title: Text('Language'), subtitle: Text('Placeholder')),
          ListTile(title: Text('Decimal precision: ${s.decimalPrecision}')),
          Slider(
            value: s.decimalPrecision.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '${s.decimalPrecision}',
            onChanged: (v) => c.setPrecision(v.round()),
          ),
          SwitchListTile(
            value: s.scientificNotation,
            title: const Text('Scientific notation'),
            onChanged: c.setScientificNotation,
          )
        ],
      ),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
      title: 'Units', body: Text('SI/Imperial defaults placeholder.'));
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
      title: 'Offline', body: Text('Download packs and storage usage placeholder.'));
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AppScaffold(title: 'About', body: Text('EngiSteps v1.0.0'));
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AppScaffold(title: 'Legal', body: Text('Legal placeholder.'));
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AppScaffold(title: 'Feedback', body: Text('Feedback stub.'));
}
