import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/tool.dart';
import '../../favorites/data/favorites_repository.dart';

import '../domain/tool_registry.dart';
import 'category_icon.dart';

class ToolsHomeScreen extends ConsumerStatefulWidget {
  const ToolsHomeScreen({super.key});
  @override
  ConsumerState<ToolsHomeScreen> createState() => _ToolsHomeState();
}

class _ToolsHomeState extends ConsumerState<ToolsHomeScreen> {
  final _search = TextEditingController();
  String? _category;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final tools = ToolRegistry.tools.where((t) {
      final text =
          '${t.title} ${t.category} ${t.description} ${t.tags.join(' ')}'
              .toLowerCase();
      return (_category == null || t.category == _category) &&
          query.split(RegExp(r'\s+')).every(text.contains);
    }).toList();
    final favorites = ref
        .watch(favoritesProvider)
        .map(ToolRegistry.find)
        .whereType<Tool>()
        .toList();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.architecture,
                          color: colors.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Solve',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Study planner',
                          onPressed: () => context.push('/planner'),
                          icon: const Icon(Icons.event_note_outlined),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'What do you need to calculate?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search a topic or choose a calculator below. Enter your values to see the working.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Find a tool, formula, or topic',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () => setState(_search.clear),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (query.isEmpty && _category == null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Convert units'),
                            onPressed: () =>
                                context.push('/tool/unit_converter'),
                          ),
                          ActionChip(
                            label: const Text('Find resistance'),
                            onPressed: () =>
                                context.push('/tool/ohms_resistors'),
                          ),
                          ActionChip(
                            label: const Text('Circuit lab'),
                            onPressed: () => context.push('/lab'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('All tools'),
                              selected: _category == null,
                              onSelected: (_) =>
                                  setState(() => _category = null),
                            ),
                          ),
                          ...ToolRegistry.categories().map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(categoryIcon(c), size: 16),
                                label: Text(c),
                                selected: _category == c,
                                onSelected: (_) => setState(
                                  () => _category = _category == c ? null : c,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (favorites.isNotEmpty &&
                        query.isEmpty &&
                        _category == null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Your essentials',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: favorites
                            .take(6)
                            .map(
                              (t) => ActionChip(
                                avatar: const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                ),
                                label: Text(t.title),
                                onPressed: () => context.push('/tool/${t.id}'),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _category ?? 'Explore the toolbox',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${tools.length} tools',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (tools.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 44,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text('No tools found. Try another topic.'),
                            TextButton(
                              onPressed: () => setState(() {
                                _search.clear();
                                _category = null;
                              }),
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent > 850
                        ? 3
                        : constraints.crossAxisExtent > 560
                        ? 2
                        : 1;
                    // Keep cards naturally sized when accessibility text scaling is large.
                    final scale =
                        MediaQuery.textScalerOf(context).scale(14) / 14;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 198 * scale.clamp(1, 3),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: tools.length,
                      itemBuilder: (context, index) {
                        final tool = tools[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/tool/${tool.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        categoryIcon(tool.category),
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tool.category,
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_outward, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    tool.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      tool.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
