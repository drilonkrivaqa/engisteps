import 'package:flutter/material.dart';

import 'app_scaffold.dart';
import 'section_card.dart';

class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ListView(
        children: [
          SectionCard(title: title, child: Text(message)),
        ],
      ),
    );
  }
}
