import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

/// 键盘绑定面板
class KeyBindingPanel extends StatelessWidget {
  final String ditKey;
  final String dashKey;
  final VoidCallback onBindDit;
  final VoidCallback onBindDash;
  final VoidCallback onInteraction;

  const KeyBindingPanel({
    super.key,
    required this.ditKey,
    required this.dashKey,
    required this.onBindDit,
    required this.onBindDash,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: SteampunkTheme.panelDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _keyChip('⚫ 点键', ditKey, onBindDit),
          const SizedBox(width: 20),
          SteampunkTheme.gearDecoration(size: 16),
          const SizedBox(width: 20),
          _keyChip('⚪ 划键', dashKey, onBindDash),
        ],
      ),
    );
  }

  Widget _keyChip(String label, String currentKey, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onInteraction();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SteampunkTheme.bgDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SteampunkTheme.brassDark.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: SteampunkTheme.labelStyle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SteampunkTheme.brass.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: SteampunkTheme.brass.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                currentKey == ' ' ? '␣' : currentKey.toUpperCase(),
                style: const TextStyle(
                  color: SteampunkTheme.brassLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.edit,
              size: 14,
              color: SteampunkTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
