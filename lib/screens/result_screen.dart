import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';

// ─── URL launcher ─────────────────────────────────────────────────────────────
Future<void> _launchUrlExternal(BuildContext context, String url) async {
  try {
    String finalUrl = url;
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:') &&
        !url.startsWith('sms:')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $url')),
      );
    }
  }
}

// ─── vCard → Android Contacts app ────────────────────────────────────────────
Future<void> _addContact(BuildContext context, String vcard) async {
  final name =
      RegExp(r'FN:([^\n\r]+)').firstMatch(vcard)?.group(1)?.trim() ?? '';
  final phone =
      RegExp(r'TEL[^:]*:([^\n\r]+)').firstMatch(vcard)?.group(1)?.trim() ?? '';
  final email =
      RegExp(r'EMAIL[^:]*:([^\n\r]+)').firstMatch(vcard)?.group(1)?.trim() ??
          '';

  bool launched = false;

  // Correct Android INSERT contact intent URI
  // android.intent.action.INSERT with type vnd.android.cursor.dir/contact
  try {
    final parts = <String>[
      'action=android.intent.action.INSERT',
      'type=vnd.android.cursor.dir%2Fcontact',
    ];
    if (name.isNotEmpty) parts.add('name=${Uri.encodeComponent(name)}');
    if (phone.isNotEmpty) parts.add('phone=${Uri.encodeComponent(phone)}');
    if (email.isNotEmpty) parts.add('email=${Uri.encodeComponent(email)}');
    parts.add('end');

    // intent: scheme format that Android understands
    final intentUri = Uri.parse('intent:#Intent;${parts.join(';')}');
    launched = await launchUrl(intentUri, mode: LaunchMode.externalApplication);
  } catch (_) {}

  // Fallback: direct contacts provider URI
  if (!launched) {
    try {
      final uri = Uri.parse('content://com.android.contacts/contacts');
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // শেষ fallback: dialog দিয়ে manually copy করতে দাও
  if (!launched && context.mounted) {
    _showContactDialog(context, name, phone, email);
  }
}

void _showContactDialog(
    BuildContext context, String name, String phone, String email) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 0.5),
      ),
      title: Text('Add Contact',
          style: TextStyle(color: context.txtPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap any field to copy, then add manually to Contacts app.',
            style: TextStyle(fontSize: 12, color: context.txtMuted),
          ),
          const SizedBox(height: 12),
          if (name.isNotEmpty) _ContactInfoTile(label: 'Name', value: name),
          if (phone.isNotEmpty) _ContactInfoTile(label: 'Phone', value: phone),
          if (email.isNotEmpty) _ContactInfoTile(label: 'Email', value: email),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              const Text('Close', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
}

// ─── Result Screen (StatefulWidget — Save button state update এর জন্য) ─────────
class ResultScreen extends StatefulWidget {
  final HistoryItem item;
  const ResultScreen({super.key, required this.item});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  Color get _primaryColor {
    switch (widget.item.scanType) {
      case ScanType.qrCode:
        return widget.item.actionType == ActionType.scanned
            ? AppColors.primary
            : AppColors.accent;
      case ScanType.barcode:
        return widget.item.actionType == ActionType.scanned
            ? AppColors.success
            : AppColors.warning;
    }
  }

  Future<void> _handleSave() async {
    // History তে add করো (না থাকলে)
    await HistoryService.add(
      content: widget.item.content,
      scanType: widget.item.scanType,
      actionType: widget.item.actionType,
      barcodeFormat: widget.item.barcodeFormat,
    );

    // Favorites এ toggle করো
    final allItems = await HistoryService.getAll();
    final existing =
        allItems.where((i) => i.content == widget.item.content).toList();

    if (existing.isNotEmpty) {
      await HistoryService.toggleFavorite(existing.first.id);
      setState(() => _isFavorite = !_isFavorite);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Removed from favorites' : 'Saved to favorites!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgDeep,
      appBar: AppBar(
        title: Text(
          widget.item.actionType == ActionType.scanned
              ? 'Scan Result'
              : 'Generated',
        ),
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
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Success icon ────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _primaryColor.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(
                      widget.item.actionType == ActionType.scanned
                          ? Icons.check_rounded
                          : Icons.auto_awesome_rounded,
                      color: _primaryColor,
                      size: 32,
                    ),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0, 0),
                          curve: Curves.easeOutBack,
                          duration: 500.ms)
                      .fadeIn(),
                  const SizedBox(height: 12),
                  Text(
                    widget.item.actionType == ActionType.scanned
                        ? 'Scan Successful'
                        : 'Generated Successfully',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.txtPrimary,
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TypeBadge(
                        label: widget.item.scanType == ScanType.qrCode
                            ? 'QR Code'
                            : 'Barcode',
                        color: _primaryColor,
                      ),
                      if (widget.item.barcodeFormat != null) ...[
                        const SizedBox(width: 6),
                        TypeBadge(
                            label: widget.item.barcodeFormat!,
                            color: context.txtMuted),
                      ],
                    ],
                  ).animate(delay: 300.ms).fadeIn(),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Content card ────────────────────────────────────────
            GlassContainer(
              borderColor: _primaryColor.withOpacity(0.15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryIcon(
                          category: widget.item.category, color: _primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        _categoryLabel(widget.item.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    widget.item.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.txtPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // ─── Smart actions ───────────────────────────────────────
            ..._buildSmartActions(context),

            // ─── Quick actions: Copy | Share (Save সরানো হয়েছে) ───────
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.content_copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.item.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => Share.share(widget.item.content),
                  ),
                ),
              ],
            ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSmartActions(BuildContext context) {
    final actions = <Widget>[];

    switch (widget.item.category) {
      case ContentCategory.url:
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Open in Browser',
              icon: Icons.open_in_new_rounded,
              onTap: () => _launchUrlExternal(context, widget.item.content),
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
        );
        break;

      case ContentCategory.email:
        actions.add(
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Send Email',
              icon: Icons.email_rounded,
              onTap: () => _launchUrlExternal(context, widget.item.content),
              color: AppColors.accent,
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
        );
        break;

      case ContentCategory.phone:
        actions.addAll([
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Call Now',
              icon: Icons.phone_rounded,
              onTap: () => _launchUrlExternal(context, widget.item.content),
              color: AppColors.success,
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Send SMS',
              icon: Icons.sms_rounded,
              onTap: () => _launchUrlExternal(
                context,
                'sms:${widget.item.content.replaceFirst('tel:', '')}',
              ),
              outlined: true,
            ),
          ).animate(delay: 450.ms).fadeIn(),
        ]);
        break;

      case ContentCategory.wifi:
        final ssid =
            RegExp(r'S:([^;]+)').firstMatch(widget.item.content)?.group(1) ??
                '';
        final pass =
            RegExp(r'P:([^;]+)').firstMatch(widget.item.content)?.group(1) ??
                '';
        actions.add(
          GlassContainer(
            borderColor: AppColors.success.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.wifi_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Text('WiFi Details',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ]),
                const SizedBox(height: 12),
                _InfoRow(label: 'Network', value: ssid),
                const SizedBox(height: 8),
                _InfoRow(label: 'Password', value: pass, isPassword: true),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
        );
        break;

      case ContentCategory.contact:
        final name = RegExp(r'FN:([^\n\r]+)')
                .firstMatch(widget.item.content)
                ?.group(1)
                ?.trim() ??
            '';
        final phone = RegExp(r'TEL[^:]*:([^\n\r]+)')
                .firstMatch(widget.item.content)
                ?.group(1)
                ?.trim() ??
            '';
        final email = RegExp(r'EMAIL[^:]*:([^\n\r]+)')
                .firstMatch(widget.item.content)
                ?.group(1)
                ?.trim() ??
            '';
        actions.addAll([
          GlassContainer(
            borderColor: AppColors.accent.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.person_rounded, color: AppColors.accent, size: 16),
                  SizedBox(width: 8),
                  Text('Contact',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                ]),
                const SizedBox(height: 12),
                if (name.isNotEmpty) _InfoRow(label: 'Name', value: name),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Phone', value: phone),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Email', value: email),
                ],
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Add to Contacts',
              icon: Icons.person_add_rounded,
              onTap: () => _addContact(context, widget.item.content),
              color: AppColors.accent,
            ),
          ).animate(delay: 450.ms).fadeIn(),
        ]);
        break;

      default:
        break;
    }

    if (actions.isEmpty) return [];
    return [...actions, const SizedBox(height: 16)];
  }

  String _categoryLabel(ContentCategory cat) {
    switch (cat) {
      case ContentCategory.url:
        return 'Website URL';
      case ContentCategory.email:
        return 'Email Address';
      case ContentCategory.phone:
        return 'Phone Number';
      case ContentCategory.wifi:
        return 'WiFi Network';
      case ContentCategory.contact:
        return 'Contact Card';
      case ContentCategory.sms:
        return 'SMS Message';
      case ContentCategory.barcode:
        return 'Barcode';
      default:
        return 'Plain Text';
    }
  }
}

// ─── Category Icon ────────────────────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final ContentCategory category;
  final Color color;
  const _CategoryIcon({required this.category, required this.color});

  IconData get _icon {
    switch (category) {
      case ContentCategory.url:
        return Icons.link_rounded;
      case ContentCategory.email:
        return Icons.email_rounded;
      case ContentCategory.phone:
        return Icons.phone_rounded;
      case ContentCategory.wifi:
        return Icons.wifi_rounded;
      case ContentCategory.contact:
        return Icons.person_rounded;
      case ContentCategory.sms:
        return Icons.sms_rounded;
      case ContentCategory.barcode:
        return Icons.qr_code_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_icon, color: color, size: 15),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? context.txtSecondary, size: 20),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(fontSize: 11, color: context.txtSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────
class _InfoRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isPassword;
  const _InfoRow(
      {required this.label, required this.value, this.isPassword = false});

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(widget.label,
              style: TextStyle(fontSize: 12, color: context.txtMuted)),
        ),
        Expanded(
          child: Text(
            widget.isPassword && _obscure
                ? '•' * widget.value.length.clamp(0, 12)
                : widget.value,
            style: TextStyle(
                fontSize: 13,
                color: context.txtPrimary,
                fontWeight: FontWeight.w500),
          ),
        ),
        if (widget.isPassword)
          GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: context.txtMuted,
              size: 16,
            ),
          ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: widget.value)),
          child: Icon(Icons.content_copy_rounded,
              color: context.txtMuted, size: 15),
        ),
      ],
    );
  }
}

// ─── Contact Info Tile (Dialog) ───────────────────────────────────────────────
class _ContactInfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _ContactInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: context.txtMuted)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: context.txtPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied!')),
              );
            },
            child: Icon(Icons.content_copy_rounded,
                color: context.txtMuted, size: 14),
          ),
        ],
      ),
    );
  }
}
