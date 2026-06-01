import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

/// 莫尔斯码输入显示区
class MorseDisplay extends StatelessWidget {
  final String morseText;
  final bool isSmall;

  const MorseDisplay({
    super.key,
    required this.morseText,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: SteampunkTheme.insetDecoration(),
      child: Row(
        children: [
          SteampunkTheme.gearDecoration(size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              morseText.isEmpty ? '等待输入 ···' : morseText,
              style: SteampunkTheme.displayMorse.copyWith(
                fontSize: isSmall ? 22 : 28,
                color: morseText.isEmpty
                    ? SteampunkTheme.textSecondary
                    : SteampunkTheme.brassLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          SteampunkTheme.gearDecoration(size: 18),
        ],
      ),
    );
  }
}
