# tkcms_user_app

The thin Flutter base of the tkcms apps (user apps and `tkcms_admin_app`):
one dark theme, two layout widgets, a busy indicator for a screen state, and
one import bringing the bloc, rxdart and auto dispose helpers together. No
firebase code of its own.

| Import | What |
|---|---|
| `theme/theme1.dart` | `themeData1({textTheme})` (dark, blue seed) and the colors `colorBlue`, `colorBlueSelected`, `colorWhite`, `colorError`, `colorGrey` |
| `view/body_container.dart` | `BodyContainer({child, width = 840})`: centered, at most `width` wide |
| `view/body_h_padding.dart` | `BodyHPadding({child})`: 16 px horizontal padding |
| `view/busy_screen_state_mixin.dart` | `BusyScreenStateMixin`, `AutoDisposedBusyScreenStateMixin` (`busyAction`, `busyStream`) |
| `view/rx_busy_indicator.dart` | `BusyIndicator(busy: ValueStream<bool>)`: a progress bar while busy |
| `tkcms_audi.dart` | `BlocProvider`, `ValueStreamBuilder`, `AutoDisposeStateBaseBloc`, `AutoDisposeBaseState`, rxdart |

Not on pub.dev: depend on it by git.

## Getting started

```yaml
dependencies:
  material_ui: ">=1.5.0"
  tkcms_user_app:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: flutter_packages/tkcms_user_app
```

Flutter (mobile, desktop, web), Dart SDK `^3.13.0`. The package is built on
`material_ui`, not on Flutter's material library: build the app on it too.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:tkcms_user_app/theme/theme1.dart';
import 'package:tkcms_user_app/view/body_container.dart';
import 'package:tkcms_user_app/view/body_h_padding.dart';

void main() {
  runApp(
    MaterialApp(
      theme: themeData1(),
      home: Scaffold(
        appBar: AppBar(title: const Text('My app')),
        body: ListView(
          children: const [
            BodyContainer(
              child: BodyHPadding(child: ListTile(title: Text('Hello'))),
            ),
          ],
        ),
      ),
    ),
  );
}
```

## What to know

- `themeData1()` returns material_ui's `ThemeData`, a class of its own:
  Flutter's `MaterialApp` (`package:flutter/material.dart`) does not accept
  it.
- Put a `BodyContainer` around each item of a list, not around the list (the
  list would lose its full width scroll area).
- `busyAction` never throws: check `result.busy` (another action was
  running, yours did not run), then `result.error`.
- `lib/main.dart` is the `flutter create` template, not part of the api.

More, with a bloc screen and the busy state, in the
[tkcms-user-app-widgets](skills/tkcms-user-app-widgets/SKILL.md) skill.
Setting the git dependency with `tkpub`:
`tkpub config set tkcms_user_app --git-url https://github.com/tekartikprj/tkcms.git --git-path flutter_packages/tkcms_user_app`.
