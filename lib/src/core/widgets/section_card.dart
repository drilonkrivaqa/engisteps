import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}