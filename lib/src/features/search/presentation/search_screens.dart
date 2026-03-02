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
    final matches = ToolRegistry.tools.where((t) => q.isEmpty || t.title.toLowerCase().contains(q)).toList();
    return AppScaffold(
      title: 'Search',
      body: Column(
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search for any tool'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => context.push('/search/results'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: matches.isEmpty
                ? const EmptyState(title: 'No results', message: 'Try another query.')
                : ListView(
                    children: matches
                        .map((tool) => ListTile(
                              title: Text(tool.title),
                              subtitle: Text(tool.category),
                              onTap: () => context.push('/tool/${tool.id}'),
                            ))
                        .toList(),
                  ),
          )
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
      body: EmptyState(title: 'Search updates live on previous screen', message: 'Use the Search screen to refine query.'),
    );
  }
}
