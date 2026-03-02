import 'package:flutter/material.dart';

import '../models/tool.dart';

class ToolListTile extends StatelessWidget {
  const ToolListTile({super.key, required this.tool, required this.onTap});

  final Tool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(tool.title),
        subtitle: Text(tool.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
