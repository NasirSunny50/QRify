import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';

// ─── Feature Card ─────────────────────────────────────────────────────────────
class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int animDelay;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.animDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.bgCard,
          border: Border.all(color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: color.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: color.withOpacity(0.2), width: 0.5),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.txtPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: context.txtMuted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animDelay))
        .fadeIn(duration: 400.ms)
        .slideY(
            begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

// ─── Glass Container ──────────────────────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? context.borderColor,
          width: borderWidth ?? 0.5,
        ),
      ),
      child: child,
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;
  final bool isLoading;
  final double? width;

  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.outlined = false,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    return SizedBox(
      width: width,
      height: 48,
      child: Material(
        color: outlined ? Colors.transparent : buttonColor,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: context.borderColor, width: 0.5),
                  )
                : null,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            outlined ? buttonColor : Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              size: 17,
                              color:
                                  outlined ? context.txtPrimary : Colors.white),
                          const SizedBox(width: 7),
                        ],
                        Text(label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  outlined ? context.txtPrimary : Colors.white,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────
class TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const TypeBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          )),
    );
  }
}

// ─── History List Item ────────────────────────────────────────────────────────
class HistoryListItem extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (item.scanType) {
      case ScanType.qrCode:
        return item.actionType == ActionType.scanned
            ? AppColors.primary
            : AppColors.accent;
      case ScanType.barcode:
        return item.actionType == ActionType.scanned
            ? AppColors.success
            : AppColors.warning;
    }
  }

  IconData get _categoryIcon {
    switch (item.category) {
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

  String get _timeAgo {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: _typeColor.withOpacity(0.2), width: 0.5),
                ),
                child: Icon(_categoryIcon, color: _typeColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.displayTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.txtPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      TypeBadge(
                        label:
                            item.scanType == ScanType.qrCode ? 'QR' : 'Barcode',
                        color: _typeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                          item.actionType == ActionType.scanned
                              ? 'Scanned'
                              : 'Generated',
                          style:
                              TextStyle(fontSize: 11, color: context.txtMuted)),
                      const SizedBox(width: 6),
                      Text('• $_timeAgo',
                          style:
                              TextStyle(fontSize: 11, color: context.txtMuted)),
                    ]),
                  ],
                ),
              ),
              // Bookmark button
              GestureDetector(
                onTap: onFavorite,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.isFavorite
                        ? AppColors.warning.withOpacity(0.1)
                        : context.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.isFavorite
                          ? AppColors.warning.withOpacity(0.3)
                          : context.borderColor,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    item.isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color:
                        item.isFavorite ? AppColors.warning : context.txtMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.txtMuted,
                letterSpacing: 1.2,
              )),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
        ],
      ),
    );
  }
}

// ─── Scan Mode Toggle ─────────────────────────────────────────────────────────
class ScanModeToggle extends StatelessWidget {
  final bool isQR;
  final ValueChanged<bool> onChanged;
  const ScanModeToggle(
      {super.key, required this.isQR, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'QR Code', selected: isQR, onTap: () => onChanged(true)),
          _Tab(
              label: 'Barcode', selected: !isQR, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.txtMuted,
            )),
      ),
    );
  }
}

// ─── Shimmer Box ──────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox(
      {super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: context.bgHighlight);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.15), width: 0.5),
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.txtPrimary,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 13, color: context.txtMuted, height: 1.5),
                textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ActionButton(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
