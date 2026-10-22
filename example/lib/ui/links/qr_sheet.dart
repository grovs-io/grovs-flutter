import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_graph.dart';
import '../../data/link_tools.dart';
import '../controls/basics.dart';
import '../controls/clipboard.dart';
import '../theme.dart';

String platformOpenCommand(String link) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? simctlCommand(link)
    : adbCommand(link, androidPackage);

String get platformOpenLabel =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'simctl' : 'adb';

class QrSheet extends StatelessWidget {
  const QrSheet(this.link, {super.key});

  final String link;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Scan on another phone',
          style: AppType.heading.copyWith(color: c.text),
        ),
        Text(
          'Tests install and deferred deep links',
          style: AppType.caption.copyWith(color: c.textMuted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Semantics(
            label: 'QR code for $link',
            child: Container(
              color: Colors.white,
              child: QrImageView(data: link, size: 220),
            ),
          ),
        ),
        Text(
          link,
          textAlign: TextAlign.center,
          style: AppType.mono.copyWith(color: c.accent),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  'Copy link',
                  () => copyText(context, link),
                  style: ButtonStyleKind.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  'Copy $platformOpenLabel',
                  () => copyText(context, platformOpenCommand(link)),
                  style: ButtonStyleKind.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
