part of '../auth_gate_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// _GoogleLogo — official Google "G" multicolor logo (24×24)
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // White circle background
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78);

    // Clip to the circle
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        Radius.circular(r)));

    // Blue (right arc)
    canvas.drawArc(
        rect, -0.52, 1.57, true, Paint()..color = const Color(0xFF4285F4));
    // Green (bottom arc)
    canvas.drawArc(
        rect, 1.05, 1.57, true, Paint()..color = const Color(0xFF34A853));
    // Yellow (bottom-left arc)
    canvas.drawArc(
        rect, 2.62, 1.57, true, Paint()..color = const Color(0xFFFBBC05));
    // Red (top-left arc)
    canvas.drawArc(
        rect, 4.19, 1.57, true, Paint()..color = const Color(0xFFEA4335));

    canvas.restore();

    // White center hole
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.48,
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar (the crossbar of the "G")
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.14, r * 0.78, r * 0.28),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
