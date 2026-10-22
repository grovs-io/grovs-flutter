import 'package:flutter/material.dart';

import '../theme.dart';
import 'basics.dart';

/// A short explanation shown behind a "?" next to a label.
class Info {
  const Info(this.title, this.body);

  final String title;
  final String body;
}

class InfoButton extends StatelessWidget {
  const InfoButton(this.info, {super.key});

  final Info info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Semantics(
      button: true,
      label: 'About ${info.title}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _InfoDialog(info),
        ),
        child: SizedBox(
          width: minTouch,
          height: minTouch,
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.textFaint),
              ),
              child: Text(
                '?',
                style: AppType.label.copyWith(
                  color: c.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog(this.info);

  final Info info;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    return Dialog(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.title, style: AppType.heading.copyWith(color: c.text)),
            const SizedBox(height: 10),
            Text(info.body, style: AppType.body.copyWith(color: c.textMuted)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextAction('Got it', () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}
