import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.bottom,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: body,
        ),
      ),
    );
  }
}