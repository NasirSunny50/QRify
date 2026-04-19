import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String initialType;
  const QRGeneratorScreen({super.key, this.initialType = 'URL'});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _previewKey = GlobalKey();
  late String _selectedType;
  String _qrData = '';
  bool _isGenerated = false;
  Color _fgColor = AppColors.darkBgDeep;
  Color _bgColor = AppColors.surfaceWhite;
  bool _isSaving = false;

  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _wifiType = 'WPA';
  bool _wifiHidden = false;

  final List<Map<String, dynamic>> _types = [
    {
      'id': 'URL',
      'label': 'URL',
      'icon': Icons.link_rounded,
      'color': AppColors.primary
    },
    {
      'id': 'Text',
      'label': 'Text',
      'icon': Icons.text_fields_rounded,
      'color': AppColors.warning
    },
    {
      'id': 'Contact',
      'label': 'Contact',
      'icon': Icons.person_rounded,
      'color': AppColors.accent
    },
    {
      'id': 'WiFi',
      'label': 'WiFi',
      'icon': Icons.wifi_rounded,
      'color': AppColors.success
    },
    {
      'id': 'Email',
      'label': 'Email',
      'icon': Icons.email_rounded,
      'color': AppColors.primaryLight
    },
    {
      'id': 'Phone',
      'label': 'Phone',
      'icon': Icons.phone_rounded,
      'color': Color(0xFFB388FF)
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _textCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _buildQRData() {
    switch (_selectedType) {
      case 'URL':
        var url = _urlCtrl.text.trim();
        if (!url.startsWith('http')) url = 'https://$url';
        return url;
      case 'Text':
        return _textCtrl.text.trim();
      case 'Contact':
        return 'BEGIN:VCARD\nVERSION:3.0\nFN:${_nameCtrl.text.trim()}\nTEL:${_phoneCtrl.text.trim()}\nEMAIL:${_emailCtrl.text.trim()}\nEND:VCARD';
      case 'WiFi':
        return 'WIFI:T:$_wifiType;S:${_ssidCtrl.text.trim()};P:${_passCtrl.text.trim()};H:$_wifiHidden;;';
      case 'Email':
        return 'mailto:${_emailCtrl.text.trim()}';
      case 'Phone':
        return 'tel:${_phoneCtrl.text.trim()}';
      default:
        return '';
    }
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    final data = _buildQRData();
    if (data.isEmpty) return;
    // Keyboard dismiss
    FocusScope.of(context).unfocus();
    setState(() {
      _qrData = data;
      _isGenerated = true;
    });
    HistoryService.add(
      content: data,
      scanType: ScanType.qrCode,
      actionType: ActionType.generated,
    );
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/qrify_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(file.path, album: 'QRify');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code saved to gallery!')),
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
      final file = File('${dir.path}/qr_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'QR Code generated with QRify');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgDeep,
      appBar: AppBar(
        title: const Text('QR Generator'),
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
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = _types[i];
                    final selected = _selectedType == t['id'];
                    final color = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = t['id'];
                        _isGenerated = false;
                      }),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : context.bgCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? color.withOpacity(0.4)
                                : context.borderColor,
                            width: selected ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: selected ? color : context.txtMuted,
                                size: 14),
                            const SizedBox(width: 6),
                            Text(t['label'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? color : context.txtMuted,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 24),
              _buildInputFields(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  label: 'Generate QR Code',
                  icon: Icons.qr_code_rounded,
                  onTap: _generate,
                ),
              ),
              if (_isGenerated && _qrData.isNotEmpty) ...[
                const SizedBox(height: 28),
                _QRPreview(
                  data: _qrData,
                  fgColor: _fgColor,
                  bgColor: _bgColor,
                  previewKey: _previewKey,
                  onSave: _saveToGallery,
                  onShare: _share,
                  isSaving: _isSaving,
                  onColorChange: (fg, bg) => setState(() {
                    _fgColor = fg;
                    _bgColor = bg;
                  }),
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

  Widget _buildInputFields() {
    switch (_selectedType) {
      case 'URL':
        return _Field(
          label: 'Website URL',
          hint: 'https://example.com',
          controller: _urlCtrl,
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Please enter a URL';
            final full = val.startsWith('http') ? val : 'https://$val';
            final uri = Uri.tryParse(full);
            if (uri == null || !uri.hasAuthority || !uri.host.contains('.')) {
              return 'Please enter a valid URL (e.g. google.com)';
            }
            return null;
          },
        );

      case 'Text':
        return _Field(
          label: 'Text Content',
          hint: 'Enter any text...',
          controller: _textCtrl,
          icon: Icons.text_fields_rounded,
          maxLines: 4,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Please enter some text' : null,
        );

      case 'Contact':
        return Column(children: [
          _Field(
            label: 'Full Name *',
            hint: 'John Doe',
            controller: _nameCtrl,
            icon: Icons.person_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Phone Number',
            hint: '+8801XXXXXXXXX',
            controller: _phoneCtrl,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final clean = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
              if (!RegExp(r'^\d+$').hasMatch(clean)) {
                return 'Only numbers, +, -, (), spaces allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Email',
            hint: 'john@example.com',
            controller: _emailCtrl,
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(v.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ]);

      case 'WiFi':
        return Column(children: [
          _Field(
            label: 'Network Name (SSID)',
            hint: 'MyWiFi',
            controller: _ssidCtrl,
            icon: Icons.wifi_rounded,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Network name is required'
                : null,
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Password',
            hint: '••••••••',
            controller: _passCtrl,
            icon: Icons.lock_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          GlassContainer(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Security Type',
                  style: TextStyle(fontSize: 13, color: context.txtSecondary)),
              const SizedBox(height: 10),
              Row(
                children: ['WPA', 'WEP', 'None'].map((type) {
                  final selected = _wifiType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _wifiType = type),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.success.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.success.withOpacity(0.4)
                                : context.borderColor,
                            width: 0.5,
                          ),
                        ),
                        child: Text(type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? AppColors.success
                                    : context.txtMuted,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Switch(
                  value: _wifiHidden,
                  onChanged: (v) => setState(() => _wifiHidden = v),
                  activeColor: AppColors.success,
                  trackColor: WidgetStateProperty.all(context.bgHighlight),
                ),
                Text('Hidden network',
                    style:
                        TextStyle(fontSize: 13, color: context.txtSecondary)),
              ]),
            ]),
          ),
        ]);

      case 'Email':
        return _Field(
          label: 'Email Address',
          hint: 'example@email.com',
          controller: _emailCtrl,
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Please enter an email address';
            if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(val)) {
              return 'Please enter a valid email (e.g. name@gmail.com)';
            }
            return null;
          },
        );

      case 'Phone':
        return _Field(
          label: 'Phone Number',
          hint: '+8801XXXXXXXXX',
          controller: _phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Please enter a phone number';
            final clean = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            if (!RegExp(r'^\d+$').hasMatch(clean)) {
              return 'Only numbers, +, -, (), spaces allowed';
            }
            return null;
          },
        );

      default:
        return const SizedBox();
    }
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: context.txtSecondary,
                fontWeight: FontWeight.w500)),
      ),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        obscureText: obscureText,
        style: TextStyle(color: context.txtPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: context.txtMuted, size: 18),
        ),
        validator: validator,
      ),
    ]);
  }
}

class _QRPreview extends StatelessWidget {
  final String data;
  final Color fgColor;
  final Color bgColor;
  final GlobalKey previewKey;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool isSaving;
  final void Function(Color fg, Color bg) onColorChange;

  const _QRPreview({
    required this.data,
    required this.fgColor,
    required this.bgColor,
    required this.previewKey,
    required this.onSave,
    required this.onShare,
    required this.isSaving,
    required this.onColorChange,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.primary.withOpacity(0.2),
      child: Column(children: [
        RepaintBoundary(
          key: previewKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: bgColor,
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: fgColor,
              ),
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: fgColor,
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          data.length > 60 ? '${data.substring(0, 60)}...' : data,
          style: TextStyle(fontSize: 11, color: context.txtMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(children: [
          Text('Style:',
              style: TextStyle(fontSize: 12, color: context.txtSecondary)),
          const SizedBox(width: 10),
          ...[
            [AppColors.darkBgDeep, AppColors.surfaceWhite],
            [AppColors.primary, AppColors.darkBgDeep],
            [AppColors.accent, AppColors.darkBgDeep],
            [AppColors.success, AppColors.darkBgDeep],
          ].map((pair) {
            final fg = pair[0];
            final bg = pair[1];
            return GestureDetector(
              onTap: () => onColorChange(fg, bg),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: context.borderColor, width: 0.5),
                ),
                child: Center(
                    child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: fg, borderRadius: BorderRadius.circular(3)),
                )),
              ),
            );
          }),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: ActionButton(
            label: 'Save',
            icon: Icons.download_rounded,
            onTap: onSave,
            isLoading: isSaving,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: ActionButton(
            label: 'Share',
            icon: Icons.share_rounded,
            onTap: onShare,
            outlined: true,
          )),
        ]),
      ]),
    );
  }
}
