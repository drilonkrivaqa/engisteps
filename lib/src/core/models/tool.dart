class ToolInputSchema {
  const ToolInputSchema({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
  });

  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
}

class ToolResult {
  const ToolResult({
    required this.mainResult,
    this.secondaryResults = const [],
    this.steps = const [],
    this.error,
  });

  final String mainResult;
  final List<MapEntry<String, String>> secondaryResults;
  final List<String> steps;
  final String? error;
}

typedef ToolCompute = ToolResult Function(Map<String, double> inputs);

class Tool {
  const Tool({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.inputs,
    required this.compute,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final List<ToolInputSchema> inputs;
  final ToolCompute compute;
}
