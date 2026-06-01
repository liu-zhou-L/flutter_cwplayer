import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

/// 解码文本显示区
class DecodeDisplay extends StatelessWidget {
  final String text;
  final ScrollController scrollController;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool isSmall;

  const DecodeDisplay({
    super.key,
    required this.text,
    required this.scrollController,
    required this.onBackspace,
    required this.onClear,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      decoration: SteampunkTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SteampunkTheme.brassDark.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                SteampunkTheme.gearDecoration(size: 14),
                const SizedBox(width: 8),
                const Text(
                  '📜 解码文本',
                  style: TextStyle(
                    color: SteampunkTheme.brass,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 文本区
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  text.isEmpty ? '（空）' : text,
                  style: SteampunkTheme.displayText.copyWith(
                    fontSize: isSmall ? 16 : 20,
                    color: text.isEmpty
                        ? SteampunkTheme.textSecondary
                        : SteampunkTheme.textPrimary,
                  ),
                  softWrap: true,
                ),
              ),
            ),
          ),
          // 操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: SteampunkTheme.bgDark.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
              border: Border(
                top: BorderSide(
                  color: SteampunkTheme.brassDark.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(Icons.backspace_outlined, '退格', onBackspace),
                _actionButton(Icons.delete_outline, '清空', onClear),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: SteampunkTheme.brass.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}
