# design_lint

Custom [`custom_lint`](https://pub.dev/packages/custom_lint) rules that enforce
the Ringo design system (`packages/ui_kit`). They stop hard-coded styling from
creeping back in and steer everyone toward the atomic components.

## Rules

| Rule                          | Flags                                                            | Use instead                                                           |
| ----------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------- |
| `avoid_hardcoded_colors`      | `Color(0xFF…)`, `Color.fromARGB/RGBO(…)`, `Colors.red`           | `context.colors.<token>`                                              |
| `avoid_hardcoded_text_styles` | inline `TextStyle(…)`                                            | `context.typography.<style>` (`.copyWith(…)` for tweaks) or `AppText` |
| `prefer_app_text`             | `Text(…)`                                                        | `AppText` / `AppText.body(…)`                                         |
| `prefer_app_text_field`       | `TextField(…)`, `TextFormField(…)`                               | `AppTextField`                                                        |
| `prefer_app_button`           | `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton` | `AppButton.primary/.secondary/.ghost/.outline/.destructive`           |

All rules are `warning` severity.

## What is exempt

The rules skip (see `lib/src/design_system_paths.dart`):

- **`packages/ui_kit/`** — the design system _defines_ these primitives
  (`AppText` wraps `Text`, `AppColors` is a table of `Color`s, …).
- **Generated files** — `*.g.dart`, `*.freezed.dart`, `*.gr.dart`,
  `*.config.dart`, `*.mocks.dart`, `*.gen.dart`.
- **Tests** — anything under a `test/` directory or ending in `_test.dart`.

## Running

`custom_lint` rules do **not** run under `dart analyze` / `flutter analyze` —
those don't load analyzer plugins. Run them explicitly:

```bash
dart run custom_lint          # whole workspace, from the repo root
melos run lint:design         # same, via the melos script
```

They also surface live in the IDE (VS Code / IntelliJ with the Dart plugin).

## Suppressing a deliberate exception

Some code legitimately needs a raw primitive — for example, a persisted color
value or a monochrome preview. Silence a single line and say why:

```dart
// ignore: avoid_hardcoded_colors — persisted category color, not a theme token
const black = Color(0xFF000000);
```

To turn a rule off for an entire package, add a local `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
custom_lint:
  rules:
    - prefer_app_text: false
```

## Wiring (already done)

- Add `custom_lint` and `design_lint` to the workspace root when these rules
  should be enabled for an application.
