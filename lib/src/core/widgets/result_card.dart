import 'package:flutter/material.dart';

import '../models/tool.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, this.result});

  final ToolResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No result yet. Enter values and press Compute.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result!.mainResult, style: Theme.of(context).textTheme.headlineSmall),
            for (final item in result!.secondaryResults)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${item.key}: ${item.value}'),
              ),
            if (result!.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(result!.error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
