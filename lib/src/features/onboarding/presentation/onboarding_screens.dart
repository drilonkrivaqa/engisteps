import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_card.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppScaffold(
        title: 'Splash',
        body: Center(child: CircularProgressIndicator()),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Welcome',
      body: SectionCard(
        title: 'Welcome to EngiSteps',
        subtitle: 'Set up your app once, then jump straight into tools next time.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: () => context.go('/pick-track'), child: const Text('Get started')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => context.go('/sign-in'), child: const Text('I already have an account')),
          ],
        ),
      ),
    );
  }
}

class PickTrackScreen extends StatelessWidget {
  const PickTrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tracks = ['Computer Eng', 'Software Eng', 'Electrical', 'Math', 'Stats'];
    return AppScaffold(
      title: 'Pick Track',
      body: SectionCard(
        title: 'Choose your focus',
        child: Column(
          children: [
            ...tracks.map((track) => ListTile(
                  title: Text(track),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/permissions'),
                )),
          ],
        ),
      ),
    );
  }
}

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Permissions',
      body: SectionCard(
        title: 'Optional permissions',
        child: Column(
          children: [
            const SwitchListTile(value: true, onChanged: null, title: Text('Notifications')),
            const SwitchListTile(value: true, onChanged: null, title: Text('Storage access')),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => context.go('/create-account'), child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create account / Guest',
      body: SectionCard(
        title: 'How would you like to continue?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: () => context.go('/profile-setup'), child: const Text('Continue as guest')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => context.go('/sign-in'), child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sign in',
      body: SectionCard(
        title: 'Sign in',
        subtitle: 'Auth form is still stubbed, but navigation now works.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: () => context.go('/profile-setup'), child: const Text('Continue')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Forgot password?')),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Forgot password',
      body: SectionCard(
        title: 'Reset password',
        subtitle: 'Reset flow is stubbed for now.',
        child: FilledButton(onPressed: () => context.go('/sign-in'), child: const Text('Back to sign in')),
      ),
    );
  }
}

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile setup',
      body: SectionCard(
        title: 'Profile setup',
        subtitle: 'Profile fields are stubbed, but completion is now functional.',
        child: FilledButton(
          onPressed: () => _finishOnboarding(context),
          child: const Text('Finish setup'),
        ),
      ),
    );
  }
}
