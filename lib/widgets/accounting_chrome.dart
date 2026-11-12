import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';

const accountingChipIdle = Color(0xFFEAF0E2);
const accountingChipText = Color(0xFF6E7C64);
const accountingNoteBg = Color(0xFFEDF1E6);
const accountingNoteText = Color(0xFF78836E);
const accountingFieldBorder = Color(0xFFDCE3D5);
const accountingOutlineBorder = Color(0xFFD9E1D1);

class AccountingPrimaryButton extends StatelessWidget {
  const AccountingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final background = onDark
        ? (enabled ? AppColors.white : const Color(0x33FFFFFF))
        : (enabled ? AppColors.primary : const Color(0xFFD5DDD0));
    final foreground = onDark
        ? (enabled ? AppColors.primary : const Color(0xB3FFFFFF))
        : AppColors.white;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground, letterSpacing: -0.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AccountingChip extends StatelessWidget {
  const AccountingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : accountingChipText;
    return Material(
      color: selected ? AppColors.primary : accountingChipIdle,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: color, letterSpacing: -0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountingTinyButton extends StatelessWidget {
  const AccountingTinyButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accountingOutlineBorder),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.4)),
        ),
      ),
    );
  }
}

class AccountingSegmentBar extends StatelessWidget {
  const AccountingSegmentBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE9EDE3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(item.$1),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == item.$1 ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected == item.$1
                        ? const [BoxShadow(color: Color(0x0F243A22), offset: Offset(0, 2), blurRadius: 3)]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected == item.$1 ? FontWeight.w700 : FontWeight.w400,
                      color: selected == item.$1 ? AppColors.ink : const Color(0xFF7A8576),
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AccountingNote extends StatelessWidget {
  const AccountingNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: accountingNoteBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: accountingNoteText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, height: 1.5, color: accountingNoteText, letterSpacing: -0.4)),
          ),
        ],
      ),
    );
  }
}

class AccountingOutlineButton extends StatelessWidget {
  const AccountingOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.dangerSolid : AppColors.primary;
    return Material(
      color: danger ? AppColors.dangerBg : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: danger ? AppColors.dangerBorder : accountingOutlineBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
