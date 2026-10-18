import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The scrollable body of a modal bottom sheet.
///
/// Applies the horizontal page padding, a top gap and a bottom gap that clears
/// **both** the keyboard and the system navigation bar. `showModalBottomSheet`
/// only removes the top padding, so a sheet that pads solely by `viewInsets`
/// hides its last content behind the navigation bar when the keyboard is down
/// (common on MIUI's 3-button navigation).
class BottomSheetBody extends StatelessWidget {
  const BottomSheetBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppBreakpoints.pagePadding(context),
        right: AppBreakpoints.pagePadding(context),
        top: AppSpacing.xl,
        bottom: media.viewInsets.bottom + media.padding.bottom + AppSpacing.xl,
      ),
      child: child,
    );
  }
}
