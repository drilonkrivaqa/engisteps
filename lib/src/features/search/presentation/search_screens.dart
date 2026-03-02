import 'package:flutter/material.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Search',
      body: Column(
        children: [
          SectionCard(title: 'Suggestions', child: Wrap(spacing: 8, children: [Chip(label: Text('Ohm\'s Law')), Chip(label: Text('Throughput'))])),
          SizedBox(height: 12),
          SectionCard(title: 'Recent searches', child: EmptyState(title: 'No recent searches', message: 'Try searching for a calculator.')),
        ],
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Search results',
      body: EmptyState(title: 'No results', message: 'Try a broader query.'),
    );
  }
}
