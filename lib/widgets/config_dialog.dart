import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';
import '../models/player_config.dart';

/// 配置对话框
class ConfigDialog extends StatefulWidget {
  final PlayerConfig config;
  final ValueChanged<PlayerConfig> onApply;
  final VoidCallback onReset;

  const ConfigDialog({
    super.key,
    required this.config,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  late PlayerConfig _local;

  @override
  void initState() {
    super.initState();
    _local = widget.config.copy();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SteampunkTheme.bgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: SteampunkTheme.brassDark.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          SteampunkTheme.gearDecoration(size: 20),
          const SizedBox(width: 10),
          const Text(
            '⚙ 配置参数',
            style: TextStyle(color: SteampunkTheme.brass, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _switchRow(
                '🔊 音效开关',
                _local.soundEnabled,
                (v) => setState(() => _local.soundEnabled = v),
              ),
              const SizedBox(height: 8),
              _sliderRow(
                '音量',
                0,
                1,
                _local.volume,
                (v) => setState(() => _local.volume = v),
                label2: '${(_local.volume * 100).round()}%',
              ),
              _sliderRow(
                '点信号时长(ms)',
                30,
                500,
                _local.dotDurationMs.toDouble(),
                (v) => setState(() => _local.dotDurationMs = v.round()),
                label2: '${_local.dotDurationMs}ms',
              ),
              _sliderRow(
                '自动键重复间隔(ms)',
                50,
                500,
                _local.autoRepeatIntervalMs.toDouble(),
                (v) => setState(() => _local.autoRepeatIntervalMs = v.round()),
                label2: '${_local.autoRepeatIntervalMs}ms',
              ),
              _sliderRow(
                '手动键长按阈值(×)',
                1.0,
                5.0,
                _local.manualLongPressThreshold,
                (v) => setState(() => _local.manualLongPressThreshold = v),
                label2:
                    '${_local.manualLongPressThreshold.toStringAsFixed(1)}x',
              ),
              _sliderRow(
                '字符间隔(×)',
                2.0,
                6.0,
                _local.charIntervalFactor,
                (v) => setState(() => _local.charIntervalFactor = v),
                label2: '${_local.charIntervalFactor.toStringAsFixed(1)}x',
              ),
              _sliderRow(
                '单词间隔(×)',
                5.0,
                10.0,
                _local.wordIntervalFactor,
                (v) => setState(() => _local.wordIntervalFactor = v),
                label2: '${_local.wordIntervalFactor.toStringAsFixed(1)}x',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _local.reset());
            widget.onReset();
          },
          child: const Text(
            '全部重置',
            style: TextStyle(color: SteampunkTheme.copper),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: SteampunkTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SteampunkTheme.brass,
            foregroundColor: SteampunkTheme.bgDark,
          ),
          onPressed: () {
            widget.onApply(_local);
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: SteampunkTheme.insetDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: SteampunkTheme.labelStyle),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: SteampunkTheme.brass,
            inactiveThumbColor: SteampunkTheme.metalMid,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double min,
    double max,
    double value,
    ValueChanged<double> onChanged, {
    String label2 = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: SteampunkTheme.insetDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: SteampunkTheme.labelStyle),
              Text(
                label2,
                style: const TextStyle(
                  color: SteampunkTheme.brassLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: SteampunkTheme.brass,
              inactiveTrackColor: SteampunkTheme.metalDark,
              thumbColor: SteampunkTheme.brassLight,
              overlayColor: SteampunkTheme.brass.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
