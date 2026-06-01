import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

/// 触摸模式下的点/划按钮组（按下即触发，无延迟）
class TouchButtons extends StatelessWidget {
  final double btnSize;
  final double btnFontSize;
  final VoidCallback onDotDown;
  final VoidCallback? onDotUp;
  final VoidCallback onDashDown;
  final VoidCallback? onDashUp;

  const TouchButtons({
    super.key,
    required this.btnSize,
    required this.btnFontSize,
    required this.onDotDown,
    this.onDotUp,
    required this.onDashDown,
    this.onDashUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton('•', onDotDown, onDotUp, SteampunkTheme.brass),
          const SizedBox(width: 36),
          SteampunkTheme.gearDecoration(size: 20),
          const SizedBox(width: 36),
          _buildButton('▬', onDashDown, onDashUp, SteampunkTheme.copper),
        ],
      ),
    );
  }

  Widget _buildButton(
    String label,
    VoidCallback onDown,
    VoidCallback? onUp,
    Color bgColor,
  ) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: onUp != null ? (_) => onUp() : null,
      onPointerCancel: onUp != null ? (_) => onUp() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: btnSize,
        height: btnSize,
        decoration: SteampunkTheme.buttonDecoration(bgColor: bgColor),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: btnFontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
