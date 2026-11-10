/// The users of an app: when each one was last seen
/// ([TkCmsAppUserSeenPinger] on the client, the `app-user/seen` command), the
/// purge of the anonymous users not seen for long and the merge of an
/// anonymous user into an account ([TkCmsAppUsersFirestore] on the server,
/// [TkCmsAppUsersApi] for the apps and an app admin).
library;

export 'src/app_user/app_user_models.dart';
export 'src/app_user/app_user_seen_pinger.dart';
export 'src/app_user/app_user_server_handler.dart';
export 'src/app_user/app_users.dart';
