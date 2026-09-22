# EngiSteps

An offline-first Flutter engineering workbench with 26 tools, expression input,
unit conversion, saved calculations, favorites, a notebook, and a study planner.

## Run locally

Use Flutter 3.38.4 / Dart 3.10.3 or a compatible newer SDK.

```sh
flutter pub get
flutter run
# Browser preview:
flutter run -d chrome
```

## Check a change

```sh
flutter analyze
flutter test
flutter build web
```

GitHub Actions runs analysis, tests, and a web release build on pushes and pull requests.

## Using the workbench

- Search by tool, category, description, or tags. Star a tool to keep it in Favorites.
- Enter numbers or expressions: `2.2k`, `470u`, `1/3`, `3*pi`, `2^-3`.
  A comma is treated as a decimal separator, not a thousands separator.
- Unit selectors multiply input values into the calculator's base units. For example,
  `2.2` with `kΩ` selected is 2200 Ω; `2.2k` with `Ω` selected is also 2200 Ω.
- The unit converter supports ten quantities, including affine temperature conversion.
- Save a result to keep its inputs, unit selections, modes, output, and steps.
  Open it from History to restore and recalculate. Editing inputs invalidates the old result.
- Settings controls dark mode, decimal precision, and scientific notation for new calculations.
  Very small and large values automatically use scientific notation to avoid misleading zeroes.
  The significant-figures tool uses its requested digit count.
- Notes save explicitly on this device. Unsaved edits survive tab switches but not app closure.
- Open the study planner using the calendar icon in the workbench header.

## Code map

- `lib/src/core/models`: tool schemas and result contracts.
- `lib/src/core/utils/smart_number_parser.dart`: expression parsing and engineering suffixes.
- `lib/src/features/tools/domain`: formula registry, execution validation, unit conversions.
- `lib/src/features/tools/presentation`: discovery and calculation interfaces.
- Feature `data` folders: Riverpod controllers with local persistence.
- `lib/src/core/navigation/app_router.dart`: the active navigation graph.
- `test`: numerical regressions, persistence compatibility, and widget workflows.

New UI calculation paths should use `ToolExecution.run`, not call a formula directly.
Validation and precision policy live at that boundary. Physical assumptions are displayed
on relevant tool screens; calculators are simplified models, not general solvers.

## Data compatibility and current scope

History retains up to 200 entries. Older records remain readable, but units and modes that
were never stored cannot be recovered; the UI labels these records before recalculation.
New records are immutable snapshots. History writes are serialized and only publish after
successful persistence. Invalid stored history records are skipped without discarding valid ones.

Data stays on the current device/browser. There is no cloud account or synchronization.
Copy working exports plain text through the clipboard. Classroom and account prototypes
remain outside active navigation; their unfinished functionality is not advertised in Settings.

See [the upgrade notes](docs/workbench-upgrade.md) for the implementation and validation scope.
