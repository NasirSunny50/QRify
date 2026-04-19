import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _previewKey = GlobalKey();
  final _inputCtrl = TextEditingController();

  String _selectedFormat = 'EAN-13';
  String _barcodeData = '';
  bool _isGenerated = false;
  bool _isSaving = false;

  final List<_BarcodeFormat> _formats = [
    _BarcodeFormat(
      id: 'EAN-13',
      label: 'EAN-13',
      description: 'Products worldwide',
      barcode: Barcode.ean13(),
      hint: '5901234123457',
      color: AppColors.warning,
      icon: Icons.shopping_bag_rounded,
      maxLength: 13,
    ),
    _BarcodeFormat(
      id: 'EAN-8',
      label: 'EAN-8',
      description: 'Small product labels',
      barcode: Barcode.ean8(),
      hint: '96385074',
      color: AppColors.accent,
      icon: Icons.label_rounded,
      maxLength: 8,
    ),
    _BarcodeFormat(
      id: 'Code128',
      label: 'Code 128',
      description: 'General purpose',
      barcode: Barcode.code128(),
      hint: 'ABC-12345',
      color: AppColors.primary,
      icon: Icons.inventory_rounded,
      maxLength: 80,
    ),
    _BarcodeFormat(
      id: 'Code39',
      label: 'Code 39',
      description: 'Alphanumeric',
      barcode: Barcode.code39(),
      hint: 'HELLO WORLD',
      color: AppColors.success,
      icon: Icons.text_fields_rounded,
      maxLength: 40,
    ),
    _BarcodeFormat(
      id: 'UPC-A',
      label: 'UPC-A',
      description: 'US retail products',
      barcode: Barcode.upcA(),
      hint: '012345678905',
      color: Color(0xFFB388FF),
      icon: Icons.storefront_rounded,
      maxLength: 12,
    ),
    _BarcodeFormat(
      id: 'PDF417',
      label: 'PDF417',
      description: '2D barcode, max ~100 chars',
      barcode: Barcode.pdf417(),
      hint: 'Enter text (max 100 chars)',
      color: AppColors.primaryLight,
      icon: Icons.view_week_rounded,
      maxLength: 100,
    ),
  ];

  _BarcodeFormat get _currentFormat =>
      _formats.firstWhere((f) => f.id == _selectedFormat);

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    final data = _inputCtrl.text.trim();
    if (data.isEmpty) return;

    // PDF417 এ ৫০+ char হলে warning toast দেখাও
    if (_selectedFormat == 'PDF417' && data.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${data.length} chars — barcode may be hard to scan. Keep under 50 for best results.',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.warning.withOpacity(0.9),
        ),
      );
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _barcodeData = data;
      _isGenerated = true;
    });
    HistoryService.add(
      content: data,
      scanType: ScanType.barcode,
      actionType: ActionType.generated,
      barcodeFormat: _selectedFormat,
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture barcode')),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // Gallery permission check
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      // Gallery তে save করো
      await Gal.putImage(file.path, album: 'QRify');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode saved to gallery!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _share() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/barcode_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Barcode generated with QRify');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgDeep,
      appBar: AppBar(
        title: const Text('Barcode Generator'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: context.txtPrimary, size: 20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Format Selector ───────────────────────────────────────
              const SectionHeader(title: 'BARCODE FORMAT'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _formats.length,
                itemBuilder: (_, i) {
                  final f = _formats[i];
                  final selected = _selectedFormat == f.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedFormat = f.id;
                      _isGenerated = false;
                      _inputCtrl.clear();
                    }),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? f.color.withOpacity(0.12)
                            : context.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? f.color.withOpacity(0.4)
                              : context.borderColor,
                          width: selected ? 1 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(f.icon,
                              color: selected ? f.color : context.txtMuted,
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  f.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        selected ? f.color : context.txtPrimary,
                                  ),
                                ),
                                Text(
                                  f.description,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.txtMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // ─── Input ─────────────────────────────────────────────────
              const SectionHeader(title: 'DATA'),
              Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor, width: 0.5),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_currentFormat.icon,
                            color: _currentFormat.color, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _currentFormat.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: _currentFormat.color,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          'Max ${_currentFormat.maxLength} chars',
                          style:
                              TextStyle(fontSize: 10, color: context.txtMuted),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _inputCtrl,
                      maxLength: _currentFormat.maxLength,
                      style: TextStyle(
                          color: context.txtPrimary,
                          fontSize: 15,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: _currentFormat.hint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterStyle:
                            TextStyle(fontSize: 10, color: context.txtMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter data';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Format hint ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentFormat.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _currentFormat.color.withOpacity(0.2), width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _currentFormat.color, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatInfo(_selectedFormat),
                        style: TextStyle(
                            fontSize: 11, color: _currentFormat.color),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  label: 'Generate Barcode',
                  icon: Icons.barcode_reader,
                  onTap: _generate,
                  color: _currentFormat.color,
                ),
              ),

              // ─── Barcode Preview ───────────────────────────────────────
              if (_isGenerated && _barcodeData.isNotEmpty) ...[
                const SizedBox(height: 28),
                _BarcodePreview(
                  data: _barcodeData,
                  format: _currentFormat,
                  previewKey: _previewKey,
                  onSave: _save,
                  onShare: _share,
                  isSaving: _isSaving,
                ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _formatInfo(String format) {
    switch (format) {
      case 'EAN-13':
        return 'Exactly 12 digits (check digit auto-calculated). Used for retail products worldwide.';
      case 'EAN-8':
        return 'Exactly 7 digits (check digit auto-calculated). Used for small products.';
      case 'Code128':
        return 'Supports all 128 ASCII characters. Most versatile 1D barcode format.';
      case 'Code39':
        return 'Uppercase letters, digits 0-9, and special chars (-, ., \$, /, +, %). Auto-adds start/stop characters.';
      case 'UPC-A':
        return 'Exactly 11 digits (check digit auto-calculated). Standard US retail barcode.';
      case 'PDF417':
        return '⚠️ Keep text under 100 chars for reliable scanning. Longer text makes the barcode too dense to scan.';
      default:
        return 'Enter valid data for this barcode format.';
    }
  }
}

class _BarcodeFormat {
  final String id;
  final String label;
  final String description;
  final Barcode barcode;
  final String hint;
  final Color color;
  final IconData icon;
  final int maxLength;

  const _BarcodeFormat({
    required this.id,
    required this.label,
    required this.description,
    required this.barcode,
    required this.hint,
    required this.color,
    required this.icon,
    required this.maxLength,
  });
}

class _BarcodePreview extends StatelessWidget {
  final String data;
  final _BarcodeFormat format;
  final GlobalKey previewKey;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool isSaving;

  const _BarcodePreview({
    required this.data,
    required this.format,
    required this.previewKey,
    required this.onSave,
    required this.onShare,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderColor: format.color.withOpacity(0.2),
      child: Column(
        children: [
          RepaintBoundary(
            key: previewKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: BarcodeWidget(
                barcode: format.barcode,
                data: data,
                width: double.infinity,
                height: format.id == 'PDF417' ? 100 : 80,
                color: Colors.black,
                backgroundColor: Colors.white,
                drawText: true,
                textPadding: 6,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black, letterSpacing: 2),
                errorBuilder: (ctx, err) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text('Invalid data for ${format.label}',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TypeBadge(label: format.label, color: format.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.length > 40 ? '${data.substring(0, 40)}...' : data,
                  style: TextStyle(
                      fontSize: 11,
                      color: context.txtMuted,
                      fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Save',
                  icon: Icons.download_rounded,
                  onTap: onSave,
                  isLoading: isSaving,
                  color: format.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: 'Share',
                  icon: Icons.share_rounded,
                  onTap: onShare,
                  outlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
