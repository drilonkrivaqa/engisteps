typedef ToolCompute = ToolResult Function(Map<String, double> inputs);

class ToolInputSchema {
  const ToolInputSchema({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.unit,
    this.required = true,
  });

  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final String? unit;
  final bool required;
}

class ToolResult {
  const ToolResult({
    required this.mainResult,
    this.secondaryResults = const <MapEntry<String, String>>[],
    this.steps = const <String>[],
    this.error,
  });

  final String mainResult;
  final List<MapEntry<String, String>> secondaryResults;
  final List<String> steps;
  final String? error;
}

class Tool {
  const Tool({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.inputs,
    required this.compute,
    this.tags = const <String>[],
    this.explain,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String? explain;
  final List<String> tags;
  final List<ToolInputSchema> inputs;
  final ToolCompute compute;
}
