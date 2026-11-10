# tkcms_test

The shared conformance suite of a tkcms api: a server app answering a few
test commands (`TkCmsTestServerApp`), its client (`TestServerApiService`) and
one entry point, `testServerTest(initContext)`, that runs the suite against
any way of reaching that server: in memory, a Firebase emulator, a node or a
Dart runtime deployment.

Not on pub.dev: add it as a dev dependency by git.

## Getting started

```yaml
dev_dependencies:
  tkcms_test:
    git:
      url: https://github.com/tekartikprj/tkcms.git
      path: packages/tkcms_test
```

Dart SDK `^3.12.0`. The whole suite on the in memory firebase
(`test/tkcms_test_server_test.dart` of this package):

```dart
import 'package:tkcms_test/tkcms_test_server_runner.dart';

void main() {
  testServerTest(initAllMemory);
}
```

For another backend, write a `Future<TestApiContext> Function()` building a
`TestServerApiService` (give it `httpsApiUri` and `callableApi` when the
deployment has both transports) and, to run the auth checks, the
`credentials` and `firebaseAuth` of an existing user. `initAllMemory` in
`lib/src/tkcms_test_server_test_runner.dart` is the template.

## What it checks

- server time over http and the callable, echo, the secured echo variants
  (v1, v2, v1 client against v2 server options) and the v2 clock fetch;
- the user: `auth/me` sees the signed in user (callable), a secured command
  sees the transport user, the callable caller, never a user id written in
  the request, none over http;
- an unknown secured command answers a `noRetry` error that names it only
  (not the registered commands nor their options);
- the retry contract: a `noRetry` error fails at once, any other error is
  tried 4 times (about 2.4 s of delays).

The server must be a `TkCmsTestServerApp` (or a subclass): the suite calls
its `test`, `echo_v1`, `echo_v2`, `echo_v1_client_v2_server` and
`test_secured_whoami` commands. A deployed test server built before these
tests were added fails them until it is deployed again.

## What to know

- `testServerTest` declares its own `setUpAll`/`tearDownAll`: call it in
  `main` or in a `group`, never in a test.
- Without `credentials`/`firebaseAuth` (or without a callable) the user
  checks are skipped or only print it (`callAuthMe`): pass them whenever the
  deployment has auth.
- On the memory (http) backend the callable caller travels in an
  unauthenticated header, trusted only when asserts are enabled: `dart test`
  enables them, a plain `dart run` of a suite file does not
  (`--enable-asserts`), and the user checks then fail.
- The secured echo passwords are public test values: never reuse them for
  real commands.
- Against a deployment: a generous `timeout:` on the group; the `throw
  before` test expects the 4 tries to fail within 10 s, a cold backend can be
  slower.

More in the [tkcms-test-server-suite](skills/tkcms-test-server-suite/SKILL.md)
skill.
