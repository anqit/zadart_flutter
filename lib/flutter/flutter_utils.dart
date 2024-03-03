import 'package:flutter/material.dart';

void showSnackbar(BuildContext context, String message, { bool hideCurrent = true }) {
  final messenger = ScaffoldMessenger.of(context);

  if (hideCurrent) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
