import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A small section eyebrow above a list or panel, with an optional trailing
/// control and an optional tap target for the whole row.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    final content = Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.navSection(context.colors)),
        ),
        ?trailing,
      ],
    );
    if (onTap == null) {
      return Semantics(header: true, child: content);
    }
    return Semantics(
      header: true,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          child: content,
        ),
      ),
    );
  }
}
