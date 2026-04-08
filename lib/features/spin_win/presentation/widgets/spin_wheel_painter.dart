import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Configuration for a single wheel segment
class WheelSegment {
  final double coinValue;
  final Color color;
  final Color textColor;

  const WheelSegment({
    required this.coinValue,
    required this.color,
    this.textColor = Colors.white,
  });
}

/// Custom painter for the spin wheel with coin segments
class SpinWheelPainter extends CustomPainter {
  final double rotation;
  final int? highlightedSegmentIndex;

  // Define 7 segments matching CoinService coin values
  // Values: [0.2, 0.5, 2, 3, 10, 25, 100]
  // Probabilities: [51%, 48.5%, 0.3%, 0.1%, 0.05%, 0.05%, 0%]
  static const List<WheelSegment> segments = [
    WheelSegment(coinValue: 0.2, color: Color(0xFF81C784)),  // Light Green - 51%
    WheelSegment(coinValue: 0.5, color: Color(0xFF66BB6A)),  // Green - 48.5%
    WheelSegment(coinValue: 2.0, color: Color(0xFF42A5F5)),  // Blue - 0.3%
    WheelSegment(coinValue: 3.0, color: Color(0xFFAB47BC)),  // Purple - 0.1%
    WheelSegment(coinValue: 10, color: Color(0xFFFF7043)),   // Deep Orange - 0.05%
    WheelSegment(coinValue: 25, color: Color(0xFFEF5350)),   // Red - 0.05%
    WheelSegment(coinValue: 100, color: Color(0xFFFFD700)),  // Gold - 0% (disabled)
  ];

  SpinWheelPainter({
    required this.rotation,
    this.highlightedSegmentIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final segmentAngle = 2 * math.pi / segments.length; // 45° in radians

    // Save canvas state
    canvas.save();
    
    // Apply rotation from center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Draw each segment
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startAngle = i * segmentAngle - math.pi / 2; // Start from top
      final isHighlighted = highlightedSegmentIndex == i;

      // Draw segment
      _drawSegment(
        canvas,
        center,
        radius,
        startAngle,
        segmentAngle,
        segment,
        isHighlighted,
      );

      // Draw text label
      _drawSegmentText(
        canvas,
        center,
        radius,
        startAngle,
        segmentAngle,
        segment,
      );
    }

    // Restore canvas state
    canvas.restore();

    // Draw center circle (not rotated)
    _drawCenterCircle(canvas, center, radius);

    // Draw border around wheel
    _drawWheelBorder(canvas, center, radius);
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double segmentAngle,
    WheelSegment segment,
    bool isHighlighted,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: isHighlighted
            ? [segment.color, segment.color.withValues(alpha: 0.7)]
            : [segment.color, segment.color.withValues(alpha: 0.8)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Draw segment border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  void _drawSegmentText(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double segmentAngle,
    WheelSegment segment,
  ) {
    // Calculate text position (middle of segment, 70% of radius)
    final textAngle = startAngle + segmentAngle / 2;
    final textRadius = radius * 0.7;
    final textX = center.dx + textRadius * math.cos(textAngle);
    final textY = center.dy + textRadius * math.sin(textAngle);

    // Create text painter
    final textSpan = TextSpan(
      text: segment.coinValue >= 1
          ? segment.coinValue.toInt().toString()
          : segment.coinValue.toString(),
      style: TextStyle(
        color: segment.textColor,
        fontSize: segment.coinValue >= 10 ? 20 : 18,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Save canvas state for text rotation
    canvas.save();
    canvas.translate(textX, textY);
    canvas.rotate(textAngle + math.pi / 2); // Rotate text to be readable
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawCenterCircle(Canvas canvas, Offset center, double radius) {
    // Draw white center circle
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(center, radius * 0.15, centerPaint);

    // Draw center border
    final centerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey[300]!
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius * 0.15, centerBorderPaint);

    // Draw coin icon in center
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🪙',
        style: TextStyle(fontSize: 30),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }

  void _drawWheelBorder(Canvas canvas, Offset center, double radius) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, borderPaint);

    // Draw inner shadow effect
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius - 4, shadowPaint);
  }

  @override
  bool shouldRepaint(SpinWheelPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.highlightedSegmentIndex != highlightedSegmentIndex;
  }

  /// Get segment index for a given coin value
  static int getSegmentIndexForCoinValue(double coinValue) {
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].coinValue == coinValue) {
        return i;
      }
    }
    return 0; // Default to first segment if not found
  }

  /// Get the angle to rotate to land on a specific segment
  static double getTargetAngleForSegment(int segmentIndex) {
    final segmentAngle = 2 * math.pi / segments.length;
    // Calculate angle to center of segment
    // Subtract to rotate clockwise, add offset to align with pointer at top
    return -(segmentIndex * segmentAngle + segmentAngle / 2);
  }
}
