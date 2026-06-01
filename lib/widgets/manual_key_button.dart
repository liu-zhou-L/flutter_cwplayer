import 'package:flutter/material.dart';
import '../theme/steampunk_theme.dart';

/// 蒸汽朋克风格手动电键按钮
class ManualKeyButton extends StatefulWidget {
  final double size;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const ManualKeyButton({
    super.key,
    required this.size,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  State<ManualKeyButton> createState() => _ManualKeyButtonState();
}

class _ManualKeyButtonState extends State<ManualKeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onPressStart();
      },
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onPressEnd();
      },
      onPointerCancel: (_) {
        setState(() => _pressed = false);
        widget.onPressEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [SteampunkTheme.brassDark, SteampunkTheme.rust]
                : [SteampunkTheme.brass, SteampunkTheme.copper],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? SteampunkTheme.brassLight
                : SteampunkTheme.brassDark,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: SteampunkTheme.brass.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: SteampunkTheme.brassLight.withValues(alpha: 0.15),
                    blurRadius: 2,
                    spreadRadius: -1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text(
              _pressed ? '发报中' : '电键',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
