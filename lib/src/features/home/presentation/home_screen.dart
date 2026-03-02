import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      body: ListView(
        children: [
          SearchBar(
            hintText: 'Search tools...',
            onTap: () => context.push('/search'),
            enabled: false,
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Categories',
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Circuits')),
                Chip(label: Text('Math')),
                Chip(label: Text('Stats')),
                Chip(label: Text('Software')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Recently used',
            child: EmptyState(
              title: 'No recent tools',
              message: 'Your computations will appear here.',
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Favorites shortcuts',
            child: EmptyState(
              title: 'No favorites yet',
              message: 'Save tools to access them faster.',
            ),
          ),
        ],
      ),
    );
  }
}
