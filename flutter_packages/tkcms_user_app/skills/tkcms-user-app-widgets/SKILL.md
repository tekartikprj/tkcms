---
name: tkcms-user-app-widgets
description: >-
  Use when building a screen of a tkcms based Flutter app with
  package:tkcms_user_app: the shared dark theme themeData1 and colour
  constants (theme/theme1.dart), the layout widgets BodyContainer and
  BodyHPadding, the busy state of a screen (BusyScreenStateMixin,
  AutoDisposedBusyScreenStateMixin, busyAction, busyStream, busySink,
  BusyActionResult, the ValueStream based BusyIndicator of
  view/rx_busy_indicator.dart) and the bloc / auto dispose bundle
  tkcms_audi.dart (BlocProvider, ValueStreamBuilder, AutoDisposeStateBaseBloc,
  AutoDisposeBaseState, audiAddStreamSubscription, rxdart BehaviorSubject).
  Does not cover the admin globals, login flow and entity screens of
  tkcms_admin_app.
---

# Screen building blocks (tkcms_user_app)

`tkcms_user_app` is the thin base of the user facing tkcms apps (and of
`tkcms_admin_app`): one dark theme, two layout widgets, the busy state mixin
of a screen and a single import that brings bloc, rxdart and auto dispose
together. It has no firebase code of its own. The model is a bloc exposing a
`ValueStream` state, a screen reading it through a `ValueStreamBuilder`, and
long actions wrapped in `busyAction` so the `BusyIndicator` shows and a
second tap is ignored.

## Guidelines

* The package is not on pub.dev, depend on it by git:

  ```yaml
  dependencies:
    tkcms_user_app:
      git:
        url: https://github.com/tekartikprj/tkcms.git
        path: flutter_packages/tkcms_user_app
  ```

* One library per concern, no `src/`:
  `package:tkcms_user_app/theme/theme1.dart` (theme and colours),
  `package:tkcms_user_app/view/body_container.dart`,
  `package:tkcms_user_app/view/body_h_padding.dart`,
  `package:tkcms_user_app/view/rx_busy_indicator.dart`,
  `package:tkcms_user_app/view/busy_screen_state_mixin.dart` (re-export of
  `tekartik_app_flutter_widget`) and `package:tkcms_user_app/tkcms_audi.dart`
  (re-export of `tekartik_app_rx_bloc_flutter/app_rx_flutter.dart`).
  `lib/main.dart` is the untouched Flutter counter template left by
  `flutter create`: never import it.
* `themeData1({TextTheme? textTheme})` returns a **dark** Material theme
  seeded on `colorBlue` (`Colors.blue`) with `adaptivePlatformDensity`, a
  floating blue snack bar, outlined inputs with always floating labels, grey
  dividers, a blue `labelSmall` and blue/white elevated buttons padded
  32x24. Pass your own `textTheme` (a custom font for instance) to keep those
  overrides on top of it; without it the default text theme is used. The
  constants are `colorBlue`, `colorBlueSelected` (`0xff1b2177`),
  `colorWhite`, `colorError` (red) and `colorGrey`. Other tekartik theme
  packages also export a `themeData1`: import with `show` or a prefix when
  both are in scope.
* `BodyContainer({child, width = 840})` centers its child in a fixed width
  box: wrap every tile, form or list item with it so wide screens keep a
  readable column, and put it *inside* the `ListView` (one per item), not
  around it, or the list loses its full width scroll area. `BodyHPadding`
  adds the 16 px horizontal padding used for text fields inside a
  `BodyContainer`. Identical widgets exist in
  `tekartik_app_flutter_widget/view/` and in `tkcms_admin_app/view/`: pick
  one library per file, importing two gives an ambiguous name.
* Busy state: mix `AutoDisposedBusyScreenStateMixin<W>` into an
  `AutoDisposeBaseState<W>` (disposed with the state) or
  `BusyScreenStateMixin<W>` into a plain `State<W>` (then call
  `busyDispose()` in `dispose`). Both give `busyAction(action)`,
  `busyStream` (`ValueStream<bool>`), `busySink` and `busy`.
* `busyAction` never throws: it returns a `BusyActionResult` with
  `busy: true` when another action is still running (yours was **not**
  run), `error`/`errorStackTrace` when the action threw, `result` otherwise.
  Always test `result.busy` first, then `result.error`, before popping or
  showing a snack. The indicator is reset only if the state is still
  mounted.
* `BusyIndicator(busy: busyStream)` from `view/rx_busy_indicator.dart` draws
  a `LinearProgressIndicator` while the stream is true and an empty
  `Container` otherwise: put it last in a `Stack` over the body so it
  overlays the top edge. It takes a `ValueStream<bool>`; the
  `BusyIndicator` of `tkcms_admin_app/view/busy_indicator.dart` takes a
  `ValueNotifier<bool>`. Same class name, choose by the type you hold.
* `tkcms_audi.dart` is the one import for the bloc pattern:
  `BlocProvider(blocBuilder: () => MyBloc(), child: MyScreen())` creates the
  bloc with the route and disposes it with it,
  `BlocProvider.of<MyBloc>(context)` reads it;
  `ValueStreamBuilder(stream:, builder:)` rebuilds on every value
  (`snapshot.data` is null until the first `add`); rxdart (`BehaviorSubject`,
  `ValueStream`) and the auto dispose helpers (`audiAddStreamSubscription`,
  `audiAddBehaviorSubject`, `audiAddFunction`) come with it.
* A bloc extends `AutoDisposeStateBaseBloc<S>`: subscribe in the constructor
  with `audiAddStreamSubscription(stream.listen(...))`, publish with
  `add(state)`, expose `state`; everything registered with `audi*` is
  cancelled by the provider. Never start a subscription with a bare
  `listen` in a bloc or a state, it survives the route.
* A screen state extends `AutoDisposeBaseState<W>` for the same reason
  (`audiAddStreamSubscription` in `initState`, cancelled in `dispose`).
* Anti-patterns: a `StatefulWidget` holding a `BehaviorSubject` it never
  closes (use `audiAddBehaviorSubject` or close it in `dispose`); running two
  `busyAction`s in a row and ignoring `busy: true` (the second one is
  silently dropped); wrapping a `ListView` in a `BodyContainer`.

## Examples

### The app theme

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_user_app/theme/theme1.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My app',
      theme: themeData1(),
      home: const Scaffold(body: Center(child: Text('Hello'))),
    );
  }
}
```

### A screen with a bloc, a busy action and the indicator

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_user_app/tkcms_audi.dart';
import 'package:tkcms_user_app/view/body_container.dart';
import 'package:tkcms_user_app/view/body_h_padding.dart';
import 'package:tkcms_user_app/view/busy_screen_state_mixin.dart';
import 'package:tkcms_user_app/view/rx_busy_indicator.dart';

class CounterState {
  final int count;
  CounterState(this.count);
}

class CounterBloc extends AutoDisposeStateBaseBloc<CounterState> {
  final _ticks = BehaviorSubject<int>.seeded(0);

  CounterBloc() {
    audiAddBehaviorSubject(_ticks);
    audiAddStreamSubscription(
      _ticks.listen((count) => add(CounterState(count))),
    );
  }

  Future<void> increment() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _ticks.add(_ticks.value + 1);
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends AutoDisposeBaseState<CounterScreen>
    with AutoDisposedBusyScreenStateMixin<CounterScreen> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<CounterBloc>(context);
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Counter')),
          body: state == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    ListView(
                      children: [
                        BodyContainer(
                          child: BodyHPadding(
                            child: ListTile(
                              title: Text('Count: ${state.count}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    BusyIndicator(busy: busyStream),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              var result = await busyAction(() => bloc.increment());
              if (result.busy) {
                return; // another action is running, this one was skipped
              }
              if (result.error != null && context.mounted) {
                var snackBar = SnackBar(content: Text('${result.error}'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

Future<void> goToCounterScreen(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        blocBuilder: () => CounterBloc(),
        child: const CounterScreen(),
      ),
    ),
  );
}
```

### Busy state on a plain State

```dart
import 'package:flutter/material.dart';
import 'package:tkcms_user_app/view/busy_screen_state_mixin.dart';
import 'package:tkcms_user_app/view/rx_busy_indicator.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen>
    with BusyScreenStateMixin<SaveScreen> {
  @override
  void dispose() {
    busyDispose(); // not automatic without AutoDisposeBaseState
    super.dispose();
  }

  Future<void> _save() async {
    var result = await busyAction(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    if (!result.busy && result.error == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(onPressed: _save, child: const Text('Save')),
          ),
          BusyIndicator(busy: busyStream),
        ],
      ),
    );
  }
}
```

## More

* Package README for the git dependency setup with `tkpub`.
