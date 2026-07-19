import 'package:flutter/material.dart';

/// Shows a snackbar with [message], hiding the current one first unless
/// [hideCurrent] is false.
void showSnackbar(BuildContext context, String message, { bool hideCurrent = true }) {
  final messenger = ScaffoldMessenger.of(context);

  if (hideCurrent) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
