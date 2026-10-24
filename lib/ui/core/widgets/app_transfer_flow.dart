import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/initial_avatar.dart';

/// The direction of a transfer between a person and the joint account.
enum AppTransferDirection { toJoint, toPerson }

/// One transfer line: who sends what to which target.
///
/// The person sits on one side, the target on the other, and the arrow points
/// in the money's direction. With no amount it collapses into a neutral line:
/// the person and "Está certo", with no arrow.
class AppTransferFlow extends StatelessWidget {
  const AppTransferFlow({
    super.key,
    required this.name,
    this.amount,
    this.direction = AppTransferDirection.toJoint,
    this.targetLabel = 'Conjunta',
    this.targetIcon = Icons.groups_outlined,
    this.detail,
  });

  final String name;

  /// The transferred amount, in euros. Null (or zero) means no transfer.
  final double? amount;

  final AppTransferDirection direction;

  /// The target's name, e.g. `Conjunta` or a goal's name.
  final String targetLabel;

  /// The icon inside the target's tinted circle.
  final IconData targetIcon;

  /// Optional supporting line below the flow.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = this.amount;
    final detail = this.detail;
    if (amount == null || amount <= 0) {
      return Row(
        children: [
          InitialAvatar(name: name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(name, color: colors.ink),
                const SizedBox(height: AppSpacing.xs),
                Text('Está certo', style: AppTextStyles.small(colors)),
              ],
            ),
          ),
        ],
      );
    }
    final toJoint = direction == AppTransferDirection.toJoint;
    final person = InitialAvatar(name: name);
    final target = _TargetBadge(icon: targetIcon);
    final leftLabel = toJoint ? name : targetLabel;
    final rightLabel = toJoint ? targetLabel : name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (toJoint) person else target,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _Label(leftLabel, color: colors.ink)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Icon(
                          toJoint ? Icons.arrow_forward : Icons.arrow_back,
                          size: AppSizes.iconSmall,
                          color: colors.primary,
                        ),
                      ),
                      Expanded(
                        child: _Label(
                          rightLabel,
                          color: colors.ink,
                          align: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppFormatters.currency(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small(
                      colors,
                    ).copyWith(color: colors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (toJoint) target else person,
          ],
        ),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(detail, style: AppTextStyles.small(colors)),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.color, this.align = TextAlign.left});

  final String text;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label(context.colors).copyWith(color: color),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.mintSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: AppSizes.iconLarge,
        color: context.colors.primaryDark,
      ),
    );
  }
}
