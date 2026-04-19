import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

// ─── Global ThemeProvider ─────────────────────────────────────────────────────
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkBgCard,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const QRifyApp());
}

class QRifyApp extends StatefulWidget {
  const QRifyApp({super.key});

  @override
  State<QRifyApp> createState() => _QRifyAppState();
}

class _QRifyAppState extends State<QRifyApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRify - Scan & Generate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDark;
    final bgColor = isDark ? AppColors.darkBgDeep : AppColors.lightBgDeep;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── App Logo ──────────────────────────────────────────
            _AppLogo()
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // ─── App Name ──────────────────────────────────────────
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(rect),
              child: const Text(
                'QRify',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 6),

            Text(
              'Scan & Generate',
              style: TextStyle(
                fontSize: 15,
                color: mutedColor,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w400,
              ),
            ).animate(delay: 450.ms).fadeIn(),

            const SizedBox(height: 8),

            Text(
              'QR Code & Barcode Scanner',
              style: TextStyle(
                fontSize: 12,
                color: mutedColor.withOpacity(0.6),
                letterSpacing: 0.3,
              ),
            ).animate(delay: 550.ms).fadeIn(),

            const SizedBox(height: 70),

            // ─── Loading dots ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(),
                      delay: Duration(milliseconds: 700 + i * 150),
                    )
                    .fadeIn(duration: 300.ms)
                    .then()
                    .fadeOut(duration: 300.ms);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Logo Widget ──────────────────────────────────────────────────────────
// app_icon.png থাকলে সেটা দেখাবে, না থাকলে custom painted logo দেখাবে
class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackLogo(),
        ),
      ),
    );
  }
}

// ─── Fallback Logo (icon না থাকলে) ────────────────────────────────────────────
class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: CustomPaint(
        painter: _QRLogoPainter(),
      ),
    );
  }
}

// ─── Custom QR Logo Painter ───────────────────────────────────────────────────
class _QRLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final purple = Paint()..color = AppColors.primary;
    final whiteO = Paint()..color = Colors.white.withOpacity(0.85);

    final s = size.width;
    final pad = s * 0.12;
    final cornerSize = s * 0.26;
    final innerPad = s * 0.05;
    final dotSize = s * 0.08;

    // Helper: draw QR corner
    void drawCorner(double x, double y) {
      final outer = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cornerSize, cornerSize),
        const Radius.circular(6),
      );
      final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + innerPad, y + innerPad, cornerSize - innerPad * 2,
            cornerSize - innerPad * 2),
        const Radius.circular(4),
      );
      final dot = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + innerPad * 2.2, y + innerPad * 2.2,
            cornerSize - innerPad * 4.4, cornerSize - innerPad * 4.4),
        const Radius.circular(3),
      );
      canvas.drawRRect(outer, white);
      canvas.drawRRect(inner, purple);
      canvas.drawRRect(dot, white);
    }

    // 3 corners
    drawCorner(pad, pad); // top-left
    drawCorner(s - pad - cornerSize, pad); // top-right
    drawCorner(pad, s - pad - cornerSize); // bottom-left

    // Center data dots — 3x3 grid
    final gridStart = s * 0.44;
    final gridX = s * 0.44;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if (row == 1 && col == 1) continue; // center skip
        final opacity = (row + col) % 2 == 0 ? 0.9 : 0.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              gridX + col * (dotSize * 1.4),
              gridStart + row * (dotSize * 1.4),
              dotSize,
              dotSize,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withOpacity(opacity),
        );
      }
    }

    // Scan line
    final scanPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pad, s * 0.5),
      Offset(s - pad, s * 0.5),
      scanPaint,
    );

    // Lightning bolt — bottom right area
    final boltPath = Path();
    final bx = s * 0.62;
    final by = s * 0.6;
    boltPath.moveTo(bx + 10, by);
    boltPath.lineTo(bx + 3, by + 12);
    boltPath.lineTo(bx + 8, by + 12);
    boltPath.lineTo(bx, by + 24);
    boltPath.lineTo(bx + 12, by + 10);
    boltPath.lineTo(bx + 7, by + 10);
    boltPath.close();
    canvas.drawPath(boltPath, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
