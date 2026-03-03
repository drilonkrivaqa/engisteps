typedef ToolCompute = ToolResult Function(Map<String, double> inputs);

enum ToolInputType {
  number,
  integer,
  angle,
  dropdown,
  toggle,
  range,
  vector,
  complex,
  matrix,
}

class ToolUnitOption {
  const ToolUnitOption({
    required this.symbol,
    required this.factorToBase,
    this.label,
  });

  final String symbol;
  final String? label;
  final double factorToBase;
}

class ToolSelectOption {
  const ToolSelectOption({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class ToolInputSchema {
  const ToolInputSchema({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.unit,
    this.required = true,
    this.type = ToolInputType.number,
    this.min,
    this.max,
    this.examples = const <String>[],
    this.options = const <ToolSelectOption>[],
    this.unitOptions = const <ToolUnitOption>[],
    this.vectorDimensions = 2,
    this.matrixRows = 2,
    this.matrixCols = 2,
  });

  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final String? unit;
  final bool required;
  final ToolInputType type;
  final double? min;
  final double? max;
  final List<String> examples;
  final List<ToolSelectOption> options;
  final List<ToolUnitOption> unitOptions;
  final int vectorDimensions;
  final int matrixRows;
  final int matrixCols;
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
