/// The auth of a tkcms app: the tekartik auth exports, [TkCmsAuthBloc] (the
/// signed in user and its app access, local or Firebase) and
/// [TkCmsFbIdentityBloc] (a user or a service account).
library;

export 'package:tekartik_firebase_auth/auth.dart';
export 'package:tekartik_firebase_auth/auth_admin.dart';
export 'package:tekartik_firebase_auth_rest/auth_rest.dart';

export 'src/auth/credentials.dart'
    show TkCmsEmailPasswordCredentials, TkCmsUidEmailPasswordCredentials;
export 'src/auth/fs_access_auth_bloc.dart'
    show
        TkCmsAuthBloc,
        TkCmsLoggedInUser,
        TkCmsLoggedInUserAccess,
        debugTkCmsAuthBloc;
export 'src/auth/roles.dart'
    show
        tkCmsUserAccessRoleAdmin,
        tkCmsUserAccessRoleUser,
        tkCmsUserAccessRoleSuperAdmin;
export 'src/bloc/fb_identity_bloc.dart'
    show
        TkCmsFbIdentityServiceAccount,
        TkCmsFbIdentity,
        TkCmsFbIdentityExtension,
        TkCmsFbIdentityBloc,
        TkCmsFbIdentityBlocState,
        TkCmsFbIdentityUser,
        globalTkCmsFbIdentityBloc,
        getTkCmsFbIdentityBloc;
