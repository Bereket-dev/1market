part of '../auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (also used by CreateAccountScreen via separate file)
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget logo;
  final String label;
  const _SocialButton(
      {required this.onPressed, required this.logo, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          logo,
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 24, height: 24, child: CustomPaint(painter: _GoogleLogoPainter()));
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), Radius.circular(r)));
    canvas.drawArc(rect, -0.52, 1.57, true, Paint()..color = const Color(0xFF4285F4));
    canvas.drawArc(rect,  1.05, 1.57, true, Paint()..color = const Color(0xFF34A853));
    canvas.drawArc(rect,  2.62, 1.57, true, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect,  4.19, 1.57, true, Paint()..color = const Color(0xFFEA4335));
    canvas.restore();
    canvas.drawCircle(Offset(cx, cy), r * 0.48, Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.14, r * 0.78, r * 0.28),
        Paint()..color = const Color(0xFF4285F4));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: Color(0xFF1877F2), shape: BoxShape.circle),
        child: const Text('f',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.0)),
      );
}
