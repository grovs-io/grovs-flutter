import 'package:flutter/material.dart';

import '../theme.dart';

const _maxHeightFraction = 0.9;

/// Bottom sheet over the whole app, tab bar included. Without [heightFraction]
/// it wraps its content and scrolls. Tap the handle to close it.
Future<void> showAppSheet(
  BuildContext context, {
  required WidgetBuilder builder,
  double? heightFraction,
}) {
  final c = GrovsColors.of(context);
  final screenHeight = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: c.background,
    barrierColor: const Color(0x4D020617),
    constraints: BoxConstraints(maxHeight: screenHeight * _maxHeightFraction),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) => _SheetBody(
      heightFraction: heightFraction,
      child: Builder(builder: builder),
    ),
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.child, this.heightFraction});

  final Widget child;
  final double? heightFraction;

  @override
  Widget build(BuildContext context) {
    final c = GrovsColors.of(context);
    final media = MediaQuery.of(context);
    final fixed = heightFraction != null;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: child,
    );
    final column = Column(
      mainAxisSize: fixed ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Close',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              height: 36,
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.neutralDot,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (fixed)
          Expanded(child: content)
        else
          Flexible(child: SingleChildScrollView(child: content)),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: fixed
            ? SizedBox(
                height: media.size.height * heightFraction!,
                child: column,
              )
            : column,
      ),
    );
  }
}
