typedef ToolCompute = ToolResult Function(Map<String, double> inputs);

class ToolInputSchema {
  const ToolInputSchema({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.unitOptions = const <String>[],
    this.isAdvanced = false,
    this.required = true,
    this.min,
    this.max,
  });

  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final List<String> unitOptions;
  final bool isAdvanced;
  final bool required;
  final double? min;
  final double? max;
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
    required this.subcategory,
    required this.description,
    required this.inputs,
    required this.compute,
    this.tags = const <String>[],
    this.isCore = false,
    this.hasGraph = false,
    this.popularity = 0,
    this.presets = const <ToolPreset>[],
  });

  final String id;
  final String title;
  final String category;
  final String subcategory;
  final String description;
  final List<String> tags;

  final List<ToolInputSchema> inputs;
  final ToolCompute compute;

  final bool isCore;
  final bool hasGraph;
  final int popularity;
  final List<ToolPreset> presets;
}