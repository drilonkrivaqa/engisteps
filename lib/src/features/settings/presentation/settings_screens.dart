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
                  key: ValueKey(settings.decimalPrecision),
                  initialValue: settings.decimalPrecision,
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

          const SectionCard(
            title: 'About',
            subtitle: 'Learn the method. Solve the next one yourself.',
            child: Text(
              'Guided circuit examples, independent practice and 26 engineering tools. Learning progress, calculations, favorites and notes are stored on this device. No account required.',
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Privacy & your data',
            child: Text(
              'EngiSteps does not send your learning answers, notes or calculations to a server. There are no ads or analytics SDKs. Data is saved locally; your device or browser backup settings may also apply. Clearing app storage or browser site data removes your saved work. Copy any working you want to keep before clearing storage.',
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Open-source licenses',
            child: TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'EngiSteps',
              ),
              child: const Text('View licenses'),
            ),
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
    body: SectionCard(
      title: 'Account',
      child: Text('Account system not implemented (offline app).'),
    ),
  );
}

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Preferences',
    body: SectionCard(
      title: 'Preferences',
      child: Text('Add preferences here later.'),
    ),
  );
}

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Units',
    body: SectionCard(
      title: 'Units',
      child: Text('Unit conversion engine can be added next.'),
    ),
  );
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Offline',
    body: SectionCard(
      title: 'Offline',
      child: Text('EngiSteps already works offline.'),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'About',
    body: SectionCard(
      title: 'About EngiSteps',
      child: Text('Engineering toolkit for students & professors.'),
    ),
  );
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Legal',
    body: SectionCard(
      title: 'Legal',
      child: Text('Add licenses and disclaimers here.'),
    ),
  );
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(
    title: 'Feedback',
    body: SectionCard(
      title: 'Feedback',
      child: Text('Add email/issue link later.'),
    ),
  );
}
