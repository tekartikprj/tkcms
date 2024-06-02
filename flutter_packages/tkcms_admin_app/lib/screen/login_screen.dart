import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tkcms_admin_app/auth/auth.dart';
import 'package:tkcms_admin_app/route/route_paths.dart';
import 'package:tkcms_admin_app/src/import_common.dart';
import 'package:tkcms_admin_app/src/import_flutter.dart';
import 'package:tkcms_admin_app/view/body_container.dart';
import 'package:tkcms_admin_app/view/body_h_padding.dart';
import 'package:tkcms_admin_app/view/info_tile.dart';
import 'package:tkcms_admin_app/view/version_tile.dart';
import 'package:tkcms_common/tkcms_auth.dart';
import 'package:tkcms_common/tkcms_firestore.dart';

import 'logged_in_screen.dart';
// ignore: unused_import

String? gDebugUsername;
String? gDebugPassword;

typedef OnLoggedIn = void Function(
    BuildContext context, FsUserAccess userAccess);

class LoginScreen extends RouteAwareStatefulWidget {
  final OnLoggedIn? onLoggedIn;
  const LoginScreen({super.key, required super.contentPath, this.onLoggedIn});

  @override
  RouteAwareState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends RouteAwareState<LoginScreen> {
  final usernameController = TextEditingController(text: gDebugUsername);
  final passwordController = TextEditingController(text: gDebugPassword);
  final loginEnabled = ValueNotifier<bool>(false);
  final busy = ValueNotifier<bool>(false);
  StreamSubscription? authLoggedInSubscription;
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    loginEnabled.dispose();
    authLoggedInSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _checkLoginEnabled();
    authLoggedInSubscription = gAuthBloc.loggedInUserAccess.where((element) {
      if (element.isLoggedIn) {
        return true;
      }
      return false;
    }).listen((fsUserAccess) {
      // ignore: avoid_print
      print('first logged in user: ${fsUserAccess.fsUserAccess}');
      if (mounted) {
        if (widget.onLoggedIn != null) {
          widget.onLoggedIn!.call(context, fsUserAccess.fsUserAccess!);
        } else {
          Navigator.of(context).pop(fsUserAccess);
        }
      }
      authLoggedInSubscription?.cancel();
    });

    super.initState();
  }

  void _checkLoginEnabled() {
    loginEnabled.value = usernameController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        !busy.value;
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<TkCmsLoggedInUser>(
        stream: gAuthBloc.loggedInUser,
        builder: (context, snapshot) {
          var title = '';
          var user = snapshot.data;
          if (snapshot.hasData) {
            if (user == null || !user.isLoggedIn) {
              title = 'Login';
            } else {
              title = 'Menu';
            }
          }
          // devPrint('loggedInUser: ${snapshot.data}');
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                if (user?.isLoggedIn ?? false)
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {
                      goToLoggedInScreen(context);
                    },
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var user = snapshot.data!;
                return Stack(
                  children: [
                    ListView(children: [
                      BodyContainer(
                        child: Column(children: [
                          if (user.isLoggedIn) ...[
                            InfoTile(titleLabel: 'Logged in as ${user.uid}'),
                          ],
                          if (!user.isLoggedIn) ...[
                            Form(
                              child: BodyContainer(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    BodyHPadding(
                                      child: TextFormField(
                                        controller: usernameController,
                                        decoration: const InputDecoration(
                                          labelText: 'User',
                                          border: OutlineInputBorder(),
                                          //hintText: 'Email',
                                        ),
                                        onChanged: (value) {
                                          _checkLoginEnabled();
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    BodyHPadding(
                                      child: TextFormField(
                                        textInputAction: TextInputAction.done,
                                        obscureText: true,
                                        controller: passwordController,
                                        decoration: const InputDecoration(
                                          labelText: 'Password',
                                          border: OutlineInputBorder(),
                                          //hintText: 'Email',
                                        ),
                                        onChanged: (value) {
                                          _checkLoginEnabled();
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    ValueListenableBuilder<bool>(
                                        valueListenable: loginEnabled,
                                        builder: (context, enabled, _) {
                                          return BodyHPadding(
                                            child: ElevatedButton(
                                              onPressed: enabled
                                                  ? () async {
                                                      await _login();
                                                      /*
                                                          auth.signInWithEmailAndPassword(
                                                              usernameController.text
                                                                  .trim(),
                                                              passwordController.text
                                                                  .trim());*/
                                                    }
                                                  : null,
                                              child: const Text('Login'),
                                            ),
                                          );
                                        }),
                                    const BodyContainer(child: VersionTile()),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ]),
                      )
                    ]),
                    //BusyIndicator(busy: busy),
                  ],
                );
              },
            ),
          );
        });
  }

  Future<void> _login() async {
    busy.value = true;
    _checkLoginEnabled();

    try {
      var username = usernameController.text.trim();
      var password = passwordController.text.trim();

      gAuthBloc.signInWithEmailAndPassword(email: username, password: password);

      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e, st) {
      if (kDebugMode) {
        print('Error $e');
      }
      if (kDebugMode) {
        print(st);
      }
    } finally {
      busy.value = false;
      _checkLoginEnabled();
    }
  }
}

Future<Object?> goToLoginScreen(BuildContext context,
    {OnLoggedIn? onLoggedIn}) async {
  return await Navigator.of(context).push<Object?>(MaterialPageRoute(
      builder: (_) => LoginScreen(
            onLoggedIn: onLoggedIn,
            contentPath: LoginContentPath(),
          )));
}

// ignore: unused_element
void onLoggedInGoToLoggedInScreen(
    BuildContext context, FsUserAccess userAccess) {
  Navigator.of(context).pop(userAccess);
  goToLoggedInScreen(context);
}
