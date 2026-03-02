import 'package:flutter/material.dart';

import '../../../core/widgets/stub_screen.dart';

class SplashScreen extends StatelessWidget { const SplashScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Splash',message:'Loading EngiSteps...'); }
class WelcomeScreen extends StatelessWidget { const WelcomeScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Welcome',message:'Welcome to EngiSteps.'); }
class PickTrackScreen extends StatelessWidget { const PickTrackScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Pick Track',message:'Computer Eng / Software Eng / Electrical / Math / Stats'); }
class PermissionsScreen extends StatelessWidget { const PermissionsScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Permissions',message:'Optional toggles for notifications/storage.'); }
class CreateAccountScreen extends StatelessWidget { const CreateAccountScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Create account / Guest',message:'Account UI stub, continue as guest supported.'); }
class SignInScreen extends StatelessWidget { const SignInScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Sign in',message:'Sign in stub screen.'); }
class ForgotPasswordScreen extends StatelessWidget { const ForgotPasswordScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Forgot password',message:'Forgot password stub screen.'); }
class ProfileSetupScreen extends StatelessWidget { const ProfileSetupScreen({super.key}); @override Widget build(BuildContext context)=>const StubScreen(title:'Profile setup',message:'Profile setup stub screen.'); }
