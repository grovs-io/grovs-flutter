import 'package:flutter/material.dart';
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

/// Opens [link] in this app, the way a tap from another app would.
Future<void> openLinkInApp(BuildContext context, String link) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await Grovs().handleUrl(link);
  } on GrovsException {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(
    const SnackBar(
      content: Text('No screen in this app opens this link'),
      duration: Duration(seconds: 2),
    ),
  );
}
