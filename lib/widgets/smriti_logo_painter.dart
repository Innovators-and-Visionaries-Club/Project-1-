import 'dart:math';
import 'package:flutter/material.dart';

class SmritiLogoWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const SmritiLogoWidget({
    super.key,
    this.size = 150,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).primaryColor;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SmritiLogoPainter(color: logoColor),
      ),
    );
  }
}

class SmritiLogoPainter extends CustomPainter {
  final Color color;

  SmritiLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Draw central solid black dot (Screen core)
    canvas.drawCircle(center, 7.0, fillPaint);

    // 2. Draw 6 concentric organic wavy rings
    final List<double> baseRadii = [22.0, 36.0, 50.0, 64.0, 78.0, 92.0];
    
    // Scale radii to fit the canvas boundary (max bounds = size.width / 2)
    final double maxRadius = baseRadii.last;
    final double scale = (min(size.width, size.height) / 2) / (maxRadius + 5);

    for (int ringIndex = 0; ringIndex < baseRadii.length; ringIndex++) {
      final double rBase = baseRadii[ringIndex] * scale;
      final path = Path();
      
      // Frequency of sine-wave bumps around the perimeter
      final double frequency = 6.0 + ringIndex;
      // Amplitude of the wavy pattern
      final double amplitude = 2.0 * scale * (1.0 + (ringIndex * 0.15));
      // Phase offset to slightly rotate each ring's waves relative to others
      final double phase = ringIndex * 0.45;

      for (int angleDegree = 0; angleDegree <= 360; angleDegree++) {
        final double theta = angleDegree * pi / 180;
        
        // Modulate radius dynamically using sine function to make it organic/wavy
        final double wave = sin(theta * frequency + phase) * amplitude;
        final double currentRadius = rBase + wave;
        
        final double x = center.dx + currentRadius * cos(theta);
        final double y = center.dy + currentRadius * sin(theta);

        if (angleDegree == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
