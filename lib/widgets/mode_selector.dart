import 'package:flutter/material.dart';
import '../models/morse_codec.dart';
import '../theme/steampunk_theme.dart';

/// 模式选择器（键控模式 + 输入源）
class ModeSelector extends StatelessWidget {
  final KeyMode keyMode;
  final InputSource inputSource;
  final ValueChanged<KeyMode> onModeChanged;
  final ValueChanged<InputSource> onSourceChanged;
  final VoidCallback onConfigTap;
  final VoidCallback onInteraction; // 用户点击任意按钮时触发，用于抑制电报输入

  const ModeSelector({
    super.key,
    required this.keyMode,
    required this.inputSource,
    required this.onModeChanged,
    required this.onSourceChanged,
    required this.onConfigTap,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _buildSegmented<KeyMode>(
          values: KeyMode.values,
          labels: const ['手动键', '半自动键', '自动键'],
          icons: const ['🔘', '⚡', '🔄'],
          selected: keyMode,
          onChanged: onModeChanged,
        ),
        _buildSegmented<InputSource>(
          values: InputSource.values,
          labels: const ['🖱 鼠标', '👆 触摸'],
          icons: const ['', ''],
          selected: inputSource,
          onChanged: onSourceChanged,
        ),
        _configButton(),
      ],
    );
  }

  Widget _buildSegmented<T extends Enum>({
    required List<T> values,
    required List<String> labels,
    required List<String> icons,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SteampunkTheme.brassDark.withValues(alpha: 0.4),
        ),
        color: SteampunkTheme.bgDark,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(values.length, (i) {
          final isSelected = values[i] == selected;
          return GestureDetector(
            onTap: () {
              onInteraction();
              onChanged(values[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? SteampunkTheme.brass.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: SteampunkTheme.brass.withValues(alpha: 0.6),
                      )
                    : null,
              ),
              child: Text(
                '${icons[i].isNotEmpty ? "${icons[i]} " : ""}${labels[i]}',
                style: TextStyle(
                  color: isSelected
                      ? SteampunkTheme.brassLight
                      : SteampunkTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _configButton() {
    return GestureDetector(
      onTap: () {
        onInteraction();
        onConfigTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SteampunkTheme.brassDark.withValues(alpha: 0.4),
          ),
          color: SteampunkTheme.bgDark,
        ),
        child: const Icon(
          Icons.settings,
          color: SteampunkTheme.brass,
          size: 22,
        ),
      ),
    );
  }
}
