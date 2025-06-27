import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/app_widget.dart';
import 'package:tekartik_app_flutter_widget/view/body_container.dart';
import 'package:tekartik_app_flutter_widget/view/body_h_padding.dart';
import 'package:tekartik_common_utils/string_utils.dart';
import 'package:tkcms_admin_app/audi/tkcms_audi.dart';
import 'package:tkcms_admin_app/l10n/app_intl.dart';
import 'package:tkcms_common/tkcms_content.dart';
import 'package:tkcms_common/tkcms_firestore.dart';
import 'package:tkcms_common/tkcms_sembast.dart';

import 'notes_screen_bloc.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<NotesScreenBloc>(context);
    var intl = appIntl(context);
    return ValueStreamBuilder(
      stream: bloc.state,
      builder: (context, snapshot) {
        var state = snapshot.data;
        var notes = state?.notes;
        var project = state?.project;
        var canAdd = project?.userAccess.isWrite ?? false;
        // print('canAdd: $canAdd ($project)');
        return Scaffold(
          appBar: AppBar(
            title: (state != null)
                ? Text(
                    state.project?.entity.name.v ?? appIntl(context).notesTitle,
                  )
                : null,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state == null) {
                return const CenteredProgress();
              }

              if (notes == null || project == null) {
                return const Center(child: Icon(Icons.error)); //edError();
              }
              return WithHeaderFooterListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  var note = notes[index];
                  // devPrint('note: $note project: $project');

                  return BodyContainer(
                    child: Column(
                      children: [
                        if (note.id == state.firstPinnedNoteId)
                          BodyHPadding(
                            child: Row(
                              children: [
                                Text(
                                  intl.notesPinned,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          )
                        else if (note.id == state.firstUnpinnedNoteId)
                          BodyHPadding(
                            child: Row(
                              children: [
                                Text(
                                  intl.notesOthers,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        NoteItemTile(note: note, eua: project),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: !canAdd
              ? null
              : FloatingActionButton(
                  onPressed: () async {
                    //await goToNoteEditScreen(context,
                    //    project: project!, note: null);
                    //await goToCreateNoteScreen(context);
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}

class NoteItemTile extends StatelessWidget {
  NoteItemTile({super.key, required this.note, required this.eua}) {
    if (note.title.v?.trimmedNonEmpty() != null) {
      title = note.title.v!.trim();
    } else {
      if (note.content.v?.trimmedNonEmpty() != null) {
        title = note.content.v!.trim();
      } else {
        title = note.id;
      }
    }
    if (note.description.v?.trimmedNonEmpty() != null) {
      subtitle = note.description.v!.trim();
    } else {
      subtitle = null;
    }
  }

  final DbNote note;
  final TkCmsEntityAndUserAccess eua;
  late final String title;
  late final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () async {
        //await goToNoteViewScreen(context, note: note, projectRef: eua.ref);
        //var cn = ContentNavigator.of(context);
        //cn.pushPath<void>(NoteContentPath(note: note));
      },
    );
  }
}

Future<void> goToNotesScreen(
  BuildContext context,
  String projectId, {
  TransitionDelegate? transitionDelegate,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          blocBuilder: () => NotesScreenBloc(projectId: projectId),
          child: const NotesScreen(),
        );
      },
    ),
  );
  /*
  var cn = ContentNavigator.of(context);
  globalNotelioPrefs.setLatestProjectRef(projectRef);
  if (projectRef.isLocal) {
    var projectId = projectRef.id;
    await cn.pushPath<void>(
        LocalProjectNotesContentPath()..project.value = projectId,
        transitionDelegate: transitionDelegate);
  } else {
    var syncedProjectId = projectRef.syncedId!;

    await cn.pushPath<void>(
        SyncedProjectNotesContentPath()..project.value = syncedProjectId,
        transitionDelegate: transitionDelegate);
  }

   */
}
