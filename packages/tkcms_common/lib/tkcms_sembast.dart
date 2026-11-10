/// The legacy local sembast mirror of the entities a user can access
/// (`cvDbEntityStore`, `cvDbUserAccessStore`, `SembastFirestoreSyncHelper`,
/// `SyncedEntitiesDb`). New local database code uses sdb
/// (`package:idb_shim` sdb, `tekaly_sdb_synced`).
library;

import 'package:sembast/timestamp.dart';

export 'package:sembast/sembast.dart';
export 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

export 'src/model/user_access.dart';
export 'src/sembast/db_entity.dart';
export 'src/sembast/db_user_access.dart';
export 'src/sembast/firestore_synced_entities_db.dart';
export 'src/sembast/sembast.dart';
export 'src/sembast/sembast_database.dart';
export 'src/sembast/sembast_firestore_entity_utils.dart';

/// Sembast timestamp
typedef DbTimestamp = Timestamp;
