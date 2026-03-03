import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tools/domain/tool_registry.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim().toLowerCase();

    final matches = ToolRegistry.tools
        .where((t) {
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    })
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return AppScaffold(
      title: 'Search',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search tools (e.g. Ohm, mean, kinetic)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: matches.isEmpty
                ? const EmptyState(
              title: 'No results',
              message: 'Try another keyword.',
              icon: Icons.search_off,
            )
                : ListView.separated(
              itemCount: matches.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final tool = matches[i];
                return ListTile(
                  title: Text(tool.title),
                  subtitle: Text('${tool.category} • ${tool.description}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tool/${tool.id}'),
                );
              },
            ),
          ),
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
      body: EmptyState(
        title: 'Search updates live',
        message: 'Use the Search screen to refine your query.',
        icon: Icons.search,
      ),
    );
  }
}