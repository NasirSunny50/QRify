import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../models/history_item.dart';
import '../widgets/common_widgets.dart';
import 'scanner_screen.dart';
import 'qr_generator_screen.dart';
import 'barcode_generator_screen.dart';
import 'history_screen.dart';
import 'result_screen.dart';

// ─── Exit Dialog ──────────────────────────────────────────────────────────────
Future<bool> _showExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBgCard
          : AppColors.lightBgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.exit_to_app_rounded,
                color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Exit QRify?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to exit the app?',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.error.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Exit',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();
  final _dashboardKey = GlobalKey<_HomeDashboardState>();

  void _goToHome() {
    setState(() => _currentIndex = 0);
    _dashboardKey.currentState?._loadRecent();
  }

  void _goToHistory() {
    setState(() => _currentIndex = 1);
    _historyKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope — back button এ exit dialog দেখাবে
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // History tab এ থাকলে Home এ যাও
        if (_currentIndex == 1) {
          _goToHome();
          return;
        }
        // Home tab এ থাকলে exit dialog দেখাও
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeDashboard(
              key: _dashboardKey,
              onSeeAll: _goToHistory,
            ),
            HistoryScreen(key: _historyKey, onBack: _goToHome),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 1) _historyKey.currentState?.reload();
            if (i == 0) _dashboardKey.currentState?._loadRecent();
          },
        ),
      ),
    );
  }
}

// ─── Home Dashboard ───────────────────────────────────────────────────────────
class _HomeDashboard extends StatefulWidget {
  final VoidCallback onSeeAll;
  const _HomeDashboard({super.key, required this.onSeeAll});

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard>
    with WidgetsBindingObserver {
  List<HistoryItem> _recentItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRecent();
  }

  Future<void> _loadRecent() async {
    final all = await HistoryService.getAll();
    if (mounted) setState(() => _recentItems = all.take(5).toList());
  }

  void _navigate(Widget screen) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = context.bgDeep;
    final cardBg = context.bgCard;
    final brd = context.borderColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QRify',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 140, 40)),
                            ),
                          ).animate().fadeIn().slideX(begin: -0.1),
                          const SizedBox(height: 2),
                          Text(
                            'Scan & generate, instantly',
                            style: TextStyle(
                                fontSize: 13, color: context.txtMuted),
                          ).animate(delay: 100.ms).fadeIn(),
                        ],
                      ),
                    ),
                    // ── Theme Toggle Button ──
                    GestureDetector(
                      onTap: () => themeProvider.toggle(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.warning.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark ? AppColors.warning : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ),
              ),
            ),

            // ─── Feature Cards ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'FEATURES'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        FeatureCard(
                          title: 'QR Scanner',
                          subtitle: 'Scan any QR code instantly',
                          icon: Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                          animDelay: 0,
                          onTap: () => _navigate(
                              const ScannerScreen(isQRMode: true)),
                        ),
                        FeatureCard(
                          title: 'QR Generator',
                          subtitle: 'Create QR for URLs, WiFi & more',
                          icon: Icons.add_box_rounded,
                          color: AppColors.accent,
                          animDelay: 80,
                          onTap: () => _navigate(const QRGeneratorScreen()),
                        ),
                        FeatureCard(
                          title: 'Barcode Scanner',
                          subtitle: 'Scan EAN, UPC, Code 128 & more',
                          icon: Icons.document_scanner_rounded,
                          color: AppColors.success,
                          animDelay: 160,
                          onTap: () => _navigate(
                              const ScannerScreen(isQRMode: false)),
                        ),
                        FeatureCard(
                          title: 'Barcode Generator',
                          subtitle: 'Generate EAN-13, Code 128 barcodes',
                          icon: Icons.barcode_reader,
                          color: AppColors.warning,
                          animDelay: 240,
                          onTap: () =>
                              _navigate(const BarcodeGeneratorScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Quick Actions ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'QUICK ACTIONS'),
                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.link_rounded, label: 'URL',
                          color: AppColors.primary,
                          onTap: () => _navigate(
                              const QRGeneratorScreen(initialType: 'URL')),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.wifi_rounded, label: 'WiFi',
                          color: AppColors.success,
                          onTap: () => _navigate(
                              const QRGeneratorScreen(initialType: 'WiFi')),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.person_rounded, label: 'Contact',
                          color: AppColors.accent,
                          onTap: () => _navigate(
                              const QRGeneratorScreen(initialType: 'Contact')),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.text_fields_rounded, label: 'Text',
                          color: AppColors.warning,
                          onTap: () => _navigate(
                              const QRGeneratorScreen(initialType: 'Text')),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
            ),

            // ─── Recent History ──────────────────────────────────────
            if (_recentItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'RECENT',
                        actionLabel: 'See all',
                        onAction: widget.onSeeAll,
                      ),
                      ...List.generate(
                        _recentItems.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HistoryListItem(
                            item: _recentItems[i],
                            onTap: () => _navigate(
                                ResultScreen(item: _recentItems[i])),
                            onFavorite: () async {
                              await HistoryService.toggleFavorite(
                                  _recentItems[i].id);
                              _loadRecent();
                            },
                            onDelete: () async {
                              await HistoryService.delete(_recentItems[i].id);
                              _loadRecent();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = context.bgCard;
    final brd = context.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: brd, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded, label: 'Home',
                selected: currentIndex == 0, onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.history_rounded, label: 'History',
                selected: currentIndex == 1, onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color:
                    selected ? AppColors.primary : context.txtMuted,
                size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : context.txtMuted,
                )),
          ],
        ),
      ),
    );
  }
}