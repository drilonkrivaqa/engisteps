class ToolInputSchema {
  const ToolInputSchema({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.unitOptions = const [],
    this.isAdvanced = false,
    this.required = true,
  });

  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final List<String> unitOptions;
  final bool isAdvanced;
  final bool required;
}

class ToolPreset {
  const ToolPreset({
    required this.name,
    required this.values,
  });

  final String name;
  final Map<String, String> values;
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
    required this.subcategory,
    required this.description,
    required this.inputs,
    required this.compute,
    this.isCore = false,
    this.hasGraph = false,
    this.popularity = 0,
    this.presets = const [],
  });

  final String id;
  final String title;
  final String category;
  final String subcategory;
  final String description;
  final List<ToolInputSchema> inputs;
  final ToolCompute compute;
  final bool isCore;
  final bool hasGraph;
  final int popularity;
  final List<ToolPreset> presets;
}
