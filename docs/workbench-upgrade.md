# Workbench upgrade

## Shipped

- Responsive card-based toolbox and a navigation rail on wide displays.
- Search with multi-word matching, clear/reset controls, and empty-state recovery.
- Resume saved work, favorites ordering, useful empty states, and reachable settings/planner.
- Scrollable calculation results, a fixed Calculate action, explicit units, and expression input.
- Domain checks for non-finite values, zero denominators, physical bounds, and significant digits.
- Corrected percentage error for negative references, zero significant-figure rounding,
  quadratic cancellation, expression precedence, and Unicode operator/suffix handling.
- Ten-quantity unit conversion with dimension checking and temperature offsets.
- Complete history snapshots with compatibility for legacy records and serialized writes.
- Invalidation of stale results, save completion feedback, and copyable calculation working.
- Safe note editing across rebuilds and provider updates; explicit local save status.
- Applied theme and precision settings, formula explanations, and physical assumptions.
- Regression suite and GitHub Actions checks.

## Verification

Calculation tests cover all 26 default tool configurations and specific numerical/domain
regressions. Persistence tests cover legacy records, malformed records, full snapshot
round trips, startup races, and write ordering. Widget tests cover search clearing, stale
result prevention, unit/mode restoration, invalid-input feedback, note preservation,
large text at phone/desktop widths, and applying dark mode through navigation.

A web release build is part of the check pipeline. Native Android/iOS release packaging,
physical-device testing, app-store signing, and deployment are separate release tasks.
No accounts, cloud synchronization, or external services were introduced.

## Follow-through

The next product work should be driven by classroom/user trials: measure time to a correct
calculation, result reuse, and which missing tools prevent users finishing their work.
Potential additions include plotted functions, comparing scenarios, result-linked notebooks,
and a versioned export/import format. The original improvement roadmap is retained as
background planning; this document describes the implemented upgrade.
