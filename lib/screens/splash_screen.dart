import 'package:flutter/material.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _loaderFade;
  late Animation<double> _exitFade;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));

    _logoFade  = CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut));
    _logoScale = Tween(begin: 0.82, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)));
    _loaderFade = CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.25, 0.5, curve: Curves.easeIn));
    _exitFade  = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.78, 1.0, curve: Curves.easeIn)));

    _ctrl.forward().then((_) {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _exitFade.value,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(children: [
            // Logo centered
            Center(
              child: FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120, height: 120,
                        child: CustomPaint(painter: _SplashLogoPainter()),
                      ),
                      const SizedBox(height: 20),
                      const Text('TILE MANAGER',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Loading indicator bottom
            Positioned(
              bottom: 72,
              left: 0, right: 0,
              child: FadeTransition(
                opacity: _loaderFade,
                child: const Center(
                  child: SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * 0.18;

    final bgPaint = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s), Radius.circular(r)), bgPaint);

    final cx   = s * 0.54;
    final midY = s * 0.50;
    final tLeft = cx - s * 0.09;

    final lines = [
      (dy: -s * 0.14, len: s * 0.28, alpha: 0.55),
      (dy: -s * 0.07, len: s * 0.36, alpha: 0.75),
      (dy:  0.0,      len: s * 0.40, alpha: 0.90),
      (dy:  s * 0.07, len: s * 0.36, alpha: 0.75),
      (dy:  s * 0.14, len: s * 0.28, alpha: 0.55),
    ];
    for (final l in lines) {
      final y  = midY + l.dy;
      final x1 = tLeft - l.len;
      final x2 = tLeft - s * 0.025;
      final shader = LinearGradient(colors: [
        const Color(0xFFE8172A).withOpacity(0),
        const Color(0xFFE8172A).withOpacity(l.alpha),
      ]).createShader(Rect.fromLTRB(x1, y - 1, x2, y + 1));
      canvas.drawLine(Offset(x1, y), Offset(x2, y),
          Paint()
            ..shader = shader
            ..strokeWidth = s * 0.022
            ..strokeCap = StrokeCap.round);
    }

    const skew = -0.22;
    final tx     = cx - skew * (s * 0.28);
    final crossH = s * 0.14;
    final crossW = s * 0.54;
    final stemW  = s * 0.18;
    final stemH  = s * 0.50;
    final topY   = s * 0.18;
    final botY   = topY + crossH + stemH;

    final tPath = Path()
      ..moveTo(tx - crossW / 2, topY)
      ..lineTo(tx + crossW / 2, topY)
      ..lineTo(tx + crossW / 2, topY + crossH)
      ..lineTo(tx + stemW / 2,  topY + crossH)
      ..lineTo(tx + stemW / 2,  botY)
      ..lineTo(tx - stemW / 2,  botY)
      ..lineTo(tx - stemW / 2,  topY + crossH)
      ..lineTo(tx - crossW / 2, topY + crossH)
      ..close();

    canvas.save();
    canvas.transform(Matrix4.skewX(skew).storage);

    final tShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF2D42), Color(0xFFB01020)],
    ).createShader(Rect.fromLTWH(tx - crossW / 2, topY, crossW, crossH + stemH));

    canvas.drawPath(tPath, Paint()..shader = tShader);
    canvas.restore();

    canvas.saveLayer(Rect.fromLTWH(0, 0, s, s),
        Paint()..blendMode = BlendMode.dstIn);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(r)),
        Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
