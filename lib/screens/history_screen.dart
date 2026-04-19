import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack; // Home এ back যাওয়ার জন্য
  const HistoryScreen({super.key, this.onBack});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _allItems = [];
  List<HistoryItem> _filtered = [];
  String _filter = 'All';
  String _search = '';
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'id': 'All', 'label': 'All', 'icon': Icons.apps_rounded},
    {'id': 'QR', 'label': 'QR', 'icon': Icons.qr_code_rounded},
    {'id': 'Barcode', 'label': 'Barcode', 'icon': Icons.barcode_reader},
    {'id': 'Scanned', 'label': 'Scanned', 'icon': Icons.document_scanner_rounded},
    {'id': 'Generated', 'label': 'Generated', 'icon': Icons.add_box_rounded},
    {'id': 'Favorites', 'label': 'Saved', 'icon': Icons.bookmark_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // HomeScreen থেকে call করার জন্য public method
  void reload() => _load();

  Future<void> _load() async {
    final items = await HistoryService.getAll();
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    var result = List<HistoryItem>.from(_allItems);
    switch (_filter) {
      case 'QR':
        result = result.where((i) => i.scanType == ScanType.qrCode).toList();
        break;
      case 'Barcode':
        result = result.where((i) => i.scanType == ScanType.barcode).toList();
        break;
      case 'Scanned':
        result = result.where((i) => i.actionType == ActionType.scanned).toList();
        break;
      case 'Generated':
        result = result.where((i) => i.actionType == ActionType.generated).toList();
        break;
      case 'Favorites':
        result = result.where((i) => i.isFavorite).toList();
        break;
    }
    if (_search.isNotEmpty) {
      result = result
          .where((i) =>
              i.content.toLowerCase().contains(_search.toLowerCase()) ||
              i.displayTitle.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    setState(() => _filtered = result);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.borderColor, width: 0.5),
        ),
        title: Text('Clear History',
            style: TextStyle(color: context.txtPrimary)),
        content: Text('This will delete all history items. Continue?',
            style: TextStyle(color: context.txtSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: context.txtMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HistoryService.clearAll();
      // Clear করার পর state সাথে সাথে update করো
      if (mounted) {
        setState(() {
          _allItems = [];
          _filtered = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Back button press হলে Home এ যাবে, push হলে pop হবে
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: context.bgDeep,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header with back button ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    // Back button — Home e pathay
                    if (widget.onBack != null)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: context.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.borderColor, width: 0.5),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              color: context.txtPrimary, size: 20),
                        ),
                      ),
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: context.txtPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_allItems.isNotEmpty)
                      GestureDetector(
                        onTap: _clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.2),
                                width: 0.5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 14),
                              SizedBox(width: 5),
                              Text('Clear',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Search ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    _search = v;
                    _applyFilters();
                  },
                  style: TextStyle(
                      color: context.txtPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search history...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.txtMuted, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _search = '';
                              _applyFilters();
                            },
                            child: Icon(Icons.close_rounded,
                                color: context.txtMuted, size: 18),
                          )
                        : null,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              // ─── Filter chips ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final selected = _filter == f['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filter = f['id']);
                          _applyFilters();
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : context.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : context.borderColor,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(f['icon'] as IconData,
                                  size: 12,
                                  color: selected
                                      ? Colors.white
                                      : context.txtMuted),
                              const SizedBox(width: 5),
                              Text(f['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : context.txtMuted,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // ─── Stats bar ───────────────────────────────────────────
              if (_allItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      _StatPill(
                          label: '${_allItems.length} total',
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      _StatPill(
                        label:
                            '${_allItems.where((i) => i.actionType == ActionType.scanned).length} scanned',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label:
                            '${_allItems.where((i) => i.actionType == ActionType.generated).length} generated',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),

              // ─── List ────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _LoadingShimmer()
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.history_rounded,
                            title: _search.isNotEmpty
                                ? 'No results found'
                                : 'No history yet',
                            subtitle: _search.isNotEmpty
                                ? 'Try a different search term'
                                : 'Start scanning or generating QR codes and barcodes',
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => HistoryListItem(
                              item: _filtered[i],
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ResultScreen(item: _filtered[i]),
                                  ),
                                );
                                _load();
                              },
                              onFavorite: () async {
                                await HistoryService.toggleFavorite(
                                    _filtered[i].id);
                                _load();
                              },
                              onDelete: () async {
                                await HistoryService.delete(_filtered[i].id);
                                _load();
                              },
                            ).animate(
                                delay: Duration(milliseconds: i * 40))
                                .fadeIn()
                                .slideX(begin: 0.05),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Container(
        height: 66,
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            ShimmerBox(width: 40, height: 40, radius: 11),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 180, height: 12, radius: 6),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 100, height: 10, radius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}