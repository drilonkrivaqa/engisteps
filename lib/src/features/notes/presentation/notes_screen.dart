import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notes_repository.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesState();
}

class _NotesState extends ConsumerState<NotesScreen> {
  late final TextEditingController _controller;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(notesProvider));
    ref.listenManual(notesProvider, (_, next) {
      if (!_dirty && _controller.text != next) _controller.text = next;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text;
    setState(() => _saving = true);
    try {
      await ref.read(notesProvider.notifier).save(text);
      if (mounted) setState(() => _dirty = _controller.text != text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your notes. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Your notebook',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A quiet place for formulas, ideas, and the things worth remembering.',
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _dirty ? 'Unsaved changes' : 'Saved on this device',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving || !_dirty ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save notes'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 16,
                maxLines: null,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(
                  hintText: 'Start with a formula, a question, or a reminder…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
