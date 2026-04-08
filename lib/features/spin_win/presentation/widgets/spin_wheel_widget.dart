import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'spin_wheel_painter.dart';

/// Animated spin wheel widget with realistic physics
class SpinWheelWidget extends StatefulWidget {
  final double size;
  final bool isSpinning;
  final double? targetCoinValue;
  final VoidCallback? onSpinComplete;

  const SpinWheelWidget({
    super.key,
    this.size = 300,
    this.isSpinning = false,
    this.targetCoinValue,
    this.onSpinComplete,
  });

  @override
  State<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends State<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _highlightedSegment;
  bool _hasCompletedSpin = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void didUpdateWidget(SpinWheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start spinning when isSpinning changes to true
    if (widget.isSpinning && !oldWidget.isSpinning && widget.targetCoinValue != null) {
      _startSpin(widget.targetCoinValue!);
    }
  }

  void _startSpin(double targetCoinValue) {
    _hasCompletedSpin = false;
    _highlightedSegment = null;

    // Get target segment index
    final targetSegmentIndex = SpinWheelPainter.getSegmentIndexForCoinValue(targetCoinValue);

    // Calculate target angle
    final targetAngle = SpinWheelPainter.getTargetAngleForSegment(targetSegmentIndex);

    // Add 4 full rotations (8π radians) for dramatic effect
    final totalRotation = (4 * 2 * math.pi) + targetAngle;

    // Update animation
    _animation = Tween<double>(
      begin: _controller.value * (2 * math.pi),
      end: totalRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation
    _controller.forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasCompletedSpin) {
      _hasCompletedSpin = true;

      // Highlight winning segment
      if (widget.targetCoinValue != null) {
        setState(() {
          _highlightedSegment = SpinWheelPainter.getSegmentIndexForCoinValue(
            widget.targetCoinValue!,
          );
        });
      }

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Notify completion
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSpinComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pointer at top
        CustomPaint(
          size: const Size(40, 30),
          painter: _PointerPainter(),
        ),
        const SizedBox(height: 8),
        // Spinning wheel
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: SpinWheelPainter(
                  rotation: _animation.value,
                  highlightedSegmentIndex: _highlightedSegment,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Painter for the pointer/indicator at top of wheel
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom center (point)
      ..lineTo(size.width / 2 - 15, 0) // Top left
      ..lineTo(size.width / 2 + 15, 0) // Top right
      ..close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}
