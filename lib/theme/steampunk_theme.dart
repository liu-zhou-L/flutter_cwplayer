import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 蒸汽朋克风格主题
class SteampunkTheme {
  SteampunkTheme._();

  // ---- 调色板 ----
  static const Color bgDark = Color(0xFF1a0f07);
  static const Color bgMedium = Color(0xFF2c1810);
  static const Color bgPanel = Color(0xFF1e120a);
  static const Color brass = Color(0xFFc9a84c);
  static const Color brassLight = Color(0xFFe6c860);
  static const Color brassDark = Color(0xFF8b6914);
  static const Color copper = Color(0xFFb87333);
  static const Color copperLight = Color(0xFFd4956a);
  static const Color rust = Color(0xFF8b4513);
  static const Color parchment = Color(0xFFf4e4c1);
  static const Color parchmentDark = Color(0xFFd4c5a0);
  static const Color metalDark = Color(0xFF2a2a2a);
  static const Color metalMid = Color(0xFF3d3d3d);
  static const Color textPrimary = Color(0xFFf4e4c1);
  static const Color textSecondary = Color(0xFFa09080);
  static const Color accent = Color(0xFFc9a84c);

  // ---- 文字样式 ----
  static const TextStyle displayMorse = TextStyle(
    fontFamily: 'monospace',
    fontSize: 28,
    letterSpacing: 8,
    fontWeight: FontWeight.w600,
    color: brassLight,
  );

  static const TextStyle displayText = TextStyle(
    fontFamily: 'monospace',
    fontSize: 20,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle labelStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    letterSpacing: 1.2,
  );

  // ---- 装饰 ----
  static BoxDecoration panelDecoration({Color? bgColor}) => BoxDecoration(
    color: bgColor ?? bgPanel,
    border: Border.all(color: brassDark.withValues(alpha: 0.5), width: 1.5),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: brassDark.withValues(alpha: 0.15),
        blurRadius: 2,
        spreadRadius: -1,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static BoxDecoration buttonDecoration({Color? bgColor}) => BoxDecoration(
    gradient: LinearGradient(
      colors: [bgColor ?? brass, (bgColor ?? brass).withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: brassLight.withValues(alpha: 0.4), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: brassLight.withValues(alpha: 0.2),
        blurRadius: 3,
        spreadRadius: -2,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration insetDecoration() => BoxDecoration(
    color: bgDark,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: brassDark.withValues(alpha: 0.4), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: 4,
        offset: const Offset(2, 2),
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: brassDark.withValues(alpha: 0.1),
        blurRadius: 2,
        offset: const Offset(-1, -1),
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  // ---- 齿纹装饰 ----
  static Widget gearDecoration({double size = 24, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GearPainter(color: color ?? brass.withValues(alpha: 0.3)),
    );
  }
}

class _GearPainter extends CustomPainter {
  final Color color;
  _GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final innerR = outerR * 0.55;

    // 外圈
    canvas.drawCircle(center, outerR, paint);
    // 内圈
    canvas.drawCircle(
      center,
      innerR,
      paint
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.15),
    );
    canvas.drawCircle(center, innerR, paint..style = PaintingStyle.stroke);

    // 齿
    const teeth = 8;
    for (int i = 0; i < teeth; i++) {
      final angle = (i / teeth) * 2 * 3.14159;
      final dx = center.dx + (outerR - 2) * math.cos(angle);
      final dy = center.dy + (outerR - 2) * math.sin(angle);
      canvas.drawCircle(
        Offset(dx, dy),
        3.5,
        paint
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.4),
      );
    }
    // 中心点
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
