import 'package:flutter/material.dart';

// Draws the flowing thin background lines shown in Screen 1
class WavyBackground extends StatelessWidget {
  final Widget child;
  const WavyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavyBackgroundPainter(),
      child: child,
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw Top Wavy Line 1
    var path1 = Path();
    path1.moveTo(0, size.height * 0.08);
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.04,
      size.width * 0.5, size.height * 0.09,
    );
    path1.quadraticBezierTo(
      size.width * 0.75, size.height * 0.14,
      size.width, size.height * 0.06,
    );
    canvas.drawPath(path1, paint);

    // Draw Top Wavy Line 2 (overlapping)
    var path2 = Path();
    path2.moveTo(0, size.height * 0.12);
    path2.quadraticBezierTo(
      size.width * 0.3, size.height * 0.16,
      size.width * 0.6, size.height * 0.08,
    );
    path2.quadraticBezierTo(
      size.width * 0.85, size.height * 0.04,
      size.width, size.height * 0.11,
    );
    canvas.drawPath(path2, paint);

    // Draw Bottom Wavy Line 1
    var path3 = Path();
    path3.moveTo(0, size.height * 0.88);
    path3.quadraticBezierTo(
      size.width * 0.25, size.height * 0.84,
      size.width * 0.5, size.height * 0.91,
    );
    path3.quadraticBezierTo(
      size.width * 0.75, size.height * 0.96,
      size.width, size.height * 0.86,
    );
    canvas.drawPath(path3, paint);

    // Draw Bottom Wavy Line 2 (overlapping)
    var path4 = Path();
    path4.moveTo(0, size.height * 0.92);
    path4.quadraticBezierTo(
      size.width * 0.35, size.height * 0.88,
      size.width * 0.65, size.height * 0.95,
    );
    path4.quadraticBezierTo(
      size.width * 0.85, size.height * 0.92,
      size.width, size.height * 0.98,
    );
    canvas.drawPath(path4, paint);

    // Draw Decorative Left Wave
    var path5 = Path();
    path5.moveTo(0, size.height * 0.4);
    path5.cubicTo(
      size.width * 0.15, size.height * 0.45,
      size.width * 0.10, size.height * 0.55,
      0, size.height * 0.6,
    );
    canvas.drawPath(path5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Organic wavy clipper for the top header of dashboard and settings screens
class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85);
    
    // Wave 1
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.70,
      size.width * 0.5, size.height * 0.88,
    );

    // Wave 2
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 1.05,
      size.width, size.height * 0.85,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
