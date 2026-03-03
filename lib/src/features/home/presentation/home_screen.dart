import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../../tools/domain/tool_registry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = <String, IconData>{
    'Circuits': Icons.bolt,
    'Electronics': Icons.memory,
    'Signals': Icons.multiline_chart,
    'Computer Arch': Icons.developer_board,
    'Physics': Icons.science,
    'Math': Icons.functions,
    'Stats': Icons.bar_chart,
    'Software': Icons.code,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Codex keeps changing provider types (AsyncValue<List<T>> vs List<T>).
    // So we normalize at runtime to always get plain Lists.
    final historyAny = ref.watch(historyProvider);
    final favoritesAny = ref.watch(favoritesProvider);

    final history = _asHistoryList(historyAny);
    final favorites = _asStringList(favoritesAny);

    final categories = ToolRegistry.tools.map((t) => t.category).toSet().toList()..sort();

    return AppScaffold(
      title: 'Home',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              hintText: 'Search tools...',
              leading: const Icon(Icons.search),
              onTap: () => context.push('/search'),
              readOnly: true,
            ),
          ),
          const SizedBox(height: 16),

          // Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              title: 'Categories',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((c) {
                  final icon = _categoryIcons[c] ?? Icons.category_outlined;
                  return ActionChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(c),
                    onPressed: () => context.push('/tools/category/$c'),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Recently used
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              title: 'Recently used',
              child: _buildRecents(context, history),
            ),
          ),

          const SizedBox(height: 12),

          // Favorites
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              title: 'Favorites',
              child: _buildFavorites(context, favorites),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecents(BuildContext context, List<HistoryEntry> history) {
    if (history.isEmpty) {
      return const EmptyState(
        title: 'No recent tools',
        message: 'Run a tool once and it appears here.',
        icon: Icons.history,
      );
    }

    final latest = history.take(5).toList();
    return Column(
      children: [
        for (final entry in latest)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ToolRegistry.byId(entry.toolId).title),
            subtitle: Text(
              entry.output,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tool/${entry.toolId}'),
          ),
      ],
    );
  }

  Widget _buildFavorites(BuildContext context, List<String> favoriteIdsList) {
    final ids = favoriteIdsList.toSet();
    if (ids.isEmpty) {
      return const EmptyState(
        title: 'No favorites yet',
        message: 'Favorite tools to access them faster.',
        icon: Icons.favorite_border,
      );
    }

    final favoriteTools = ToolRegistry.tools.where((t) => ids.contains(t.id)).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return Column(
      children: [
        for (final tool in favoriteTools.take(6))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: Text(tool.title),
            subtitle: Text(tool.category),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tool/${tool.id}'),
          ),
      ],
    );
  }

  // ---------- normalization helpers ----------

  List<String> _asStringList(Object? value) {
    // If it's already a List<String>
    if (value is List<String>) return value;

    // If it's AsyncValue<List<String>>
    if (value is AsyncValue) {
      return value.maybeWhen<List<String>>(
        data: (d) => d is List<String> ? d : <String>[],
        orElse: () => <String>[],
      );
    }

    // If it's something else (defensive)
    return <String>[];
  }

  List<HistoryEntry> _asHistoryList(Object? value) {
    if (value is List<HistoryEntry>) return value;

    if (value is AsyncValue) {
      return value.maybeWhen<List<HistoryEntry>>(
        data: (d) => d is List<HistoryEntry> ? d : <HistoryEntry>[],
        orElse: () => <HistoryEntry>[],
      );
    }

    return <HistoryEntry>[];
  }
}