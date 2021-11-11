import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/settings/home.dart';
import 'package:flutter/material.dart';

class SettingsIntent extends Intent {
  final BuildContext context;

  const SettingsIntent(this.context);
}

class SettingsAction extends Action<SettingsIntent> {
  final DocumentBloc bloc;

  SettingsAction(this.bloc);

  @override
  Object? invoke(SettingsIntent intent) {
    showDialog(
        context: intent.context,
        builder: (context) => Dialog(
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 400, maxWidth: 600),
                child: const SettingsPage(isDialog: true))));
  }
}