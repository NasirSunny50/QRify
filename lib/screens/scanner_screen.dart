import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool isQRMode;
  const ScannerScreen({super.key, required this.isQRMode});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _scanLineController;
  bool _isQRMode = true;
  bool _torchOn = false;
  bool _isFrontCamera = false;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _isQRMode = widget.isQRMode;
    _controller = MobileScannerController(
      // normal speed দিলে PDF417 এর মতো complex barcode ভালো detect হয়
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
      formats: const [
        BarcodeFormat.all,
      ],
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final value = barcode.rawValue ?? '';
    if (value.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    HapticFeedback.mediumImpact();
    await _controller.stop();

    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: value,
      scanType: _isQRMode ? ScanType.qrCode : ScanType.barcode,
      actionType: ActionType.scanned,
      barcodeFormat: barcode.format.name,
      createdAt: DateTime.now(),
    );

    await HistoryService.add(
      content: value,
      scanType: _isQRMode ? ScanType.qrCode : ScanType.barcode,
      actionType: ActionType.scanned,
      barcodeFormat: barcode.format.name,
    );

    if (mounted) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => ResultScreen(item: item),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      await _controller.start();
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanning image...'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      await _controller.stop();

      final BarcodeCapture? capture =
          await _controller.analyzeImage(image.path);

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code or barcode found in this image'),
              duration: Duration(seconds: 3),
            ),
          );
          await _controller.start();
        }
        return;
      }

      final barcode = capture.barcodes.first;
      final value = barcode.rawValue ?? '';
      if (value.isEmpty) {
        await _controller.start();
        return;
      }

      // Format দেখে automatically QR নাকি Barcode ঠিক করো
      final isQR = barcode.format == BarcodeFormat.qrCode ||
          barcode.format == BarcodeFormat.aztec ||
          barcode.format == BarcodeFormat.dataMatrix;

      HapticFeedback.mediumImpact();

      final item = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: value,
        scanType: isQR ? ScanType.qrCode : ScanType.barcode,
        actionType: ActionType.scanned,
        barcodeFormat: barcode.format.name,
        createdAt: DateTime.now(),
      );

      await HistoryService.add(
        content: value,
        scanType: isQR ? ScanType.qrCode : ScanType.barcode,
        actionType: ActionType.scanned,
        barcodeFormat: barcode.format.name,
      );

      if (mounted) {
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => ResultScreen(item: item),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        await _controller.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        title: ScanModeToggle(
          isQR: _isQRMode,
          onChanged: (v) => setState(() => _isQRMode = v),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _torchOn
                    ? AppColors.warning.withOpacity(0.3)
                    : Colors.black38,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _torchOn
                        ? AppColors.warning.withOpacity(0.5)
                        : Colors.white24,
                    width: 0.5),
              ),
              child: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? AppColors.warning : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── Camera ──────────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ─── Dark overlay with cutout ─────────────────────────────────
          _ScannerOverlay(isQRMode: _isQRMode),

          // ─── Animated scan line ────────────────────────────────────────
          Positioned.fill(
            child:
                _ScanLine(animation: _scanLineController, isQRMode: _isQRMode),
          ),

          // ─── Bottom controls ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              onFlip: () async {
                await _controller.switchCamera();
                setState(() => _isFrontCamera = !_isFrontCamera);
              },
              onGallery: _pickFromGallery,
              isQRMode: _isQRMode,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scanner Overlay (dark mask with transparent center) ─────────────────────
class _ScannerOverlay extends StatelessWidget {
  final bool isQRMode;
  const _ScannerOverlay({required this.isQRMode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // PDF417 লম্বা ও চওড়া — তাই barcode mode এ বড় viewport
    final cutoutWidth = isQRMode ? 260.0 : size.width * 0.85;
    final cutoutHeight = isQRMode ? 260.0 : 160.0;
    final cutoutTop = (size.height - cutoutHeight) / 2 - 40;

    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(
        cutoutRect: Rect.fromCenter(
          center: Offset(size.width / 2, cutoutTop + cutoutHeight / 2),
          width: cutoutWidth,
          height: cutoutHeight,
        ),
        cornerColor: AppColors.primary,
        isQR: isQRMode,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color cornerColor;
  final bool isQR;

  const _OverlayPainter({
    required this.cutoutRect,
    required this.cornerColor,
    required this.isQR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw dark overlay
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Clear cutout area
    final rrect =
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16));
    canvas.drawRRect(rrect, clearPaint);
    canvas.restore();

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final r = cutoutRect;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.top + cornerLength)
          ..lineTo(r.left, r.top + 12)
          ..arcToPoint(Offset(r.left + 12, r.top),
              radius: const Radius.circular(12))
          ..lineTo(r.left + cornerLength, r.top),
        cornerPaint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(r.right - cornerLength, r.top)
          ..lineTo(r.right - 12, r.top)
          ..arcToPoint(Offset(r.right, r.top + 12),
              radius: const Radius.circular(12))
          ..lineTo(r.right, r.top + cornerLength),
        cornerPaint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.bottom - cornerLength)
          ..lineTo(r.left, r.bottom - 12)
          ..arcToPoint(Offset(r.left + 12, r.bottom),
              radius: const Radius.circular(12))
          ..lineTo(r.left + cornerLength, r.bottom),
        cornerPaint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(r.right - cornerLength, r.bottom)
          ..lineTo(r.right - 12, r.bottom)
          ..arcToPoint(Offset(r.right, r.bottom - 12),
              radius: const Radius.circular(12))
          ..lineTo(r.right, r.bottom - cornerLength),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLine extends StatelessWidget {
  final AnimationController animation;
  final bool isQRMode;

  const _ScanLine({required this.animation, required this.isQRMode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutoutWidth = isQRMode ? 260.0 : size.width * 0.85;
    final cutoutHeight = isQRMode ? 260.0 : 160.0;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2 - 40;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final scanY = cutoutTop + animation.value * cutoutHeight;
        return CustomPaint(
          painter: _ScanLinePainter(
            y: scanY,
            left: cutoutLeft,
            right: cutoutLeft + cutoutWidth,
          ),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double y;
  final double left;
  final double right;

  const _ScanLinePainter(
      {required this.y, required this.left, required this.right});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withOpacity(0.8),
          AppColors.primary,
          AppColors.primary.withOpacity(0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(left, y, right, y + 2))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left, y), Offset(right, y), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) => old.y != y;
}

class _BottomControls extends StatelessWidget {
  final VoidCallback onFlip;
  final VoidCallback onGallery;
  final bool isQRMode;

  const _BottomControls(
      {required this.onFlip, required this.onGallery, required this.isQRMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            isQRMode
                ? 'Point camera at a QR code to scan'
                : 'Point camera at a barcode to scan',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.image_rounded,
                label: 'Gallery',
                onTap: onGallery,
              ),
              _ControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                onTap: onFlip,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
