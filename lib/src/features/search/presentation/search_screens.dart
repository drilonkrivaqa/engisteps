import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../tools/domain/tool_registry.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Search',
      body: ListView(
        children: [
          SectionCard(
            title: 'Find tools',
            subtitle: 'Search by name, category, or keywords.',
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'e.g. Ohm, capacitor, Nyquist, mean...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (v) => context.push('/search/results?q=${Uri.encodeComponent(v)}'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push('/search/results?q=${Uri.encodeComponent(_ctrl.text)}'),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Quick picks',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _QuickChip('Ohm'),
                _QuickChip('Power'),
                _QuickChip('RC'),
                _QuickChip('Nyquist'),
                _QuickChip('Mean'),
                _QuickChip('Binary'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: () => context.push('/search/results?q=${Uri.encodeComponent(text)}'),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    final results = ToolRegistry.tools.where((t) {
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.subcategory.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));

    return AppScaffold(
      title: 'Results',
      actions: [
        IconButton(
          tooltip: 'New search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
        ),
      ],
      body: results.isEmpty
          ? EmptyState(
        title: 'No matches',
        message: 'Try a different keyword. You searched: "$query".',
        icon: Icons.search_off,
      )
          : ListView(
        children: [
          SectionCard(
            title: 'Matches',
            trailing: Text('${results.length}'),
            child: Column(
              children: results
                  .map((t) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.title),
                subtitle: Text('${t.category} • ${t.subcategory}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tool/${t.id}'),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}