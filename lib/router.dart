import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:life_os/features/dashboard/presentation/dashboard_screen.dart';
import 'package:life_os/features/finance/presentation/finance_screen.dart';
import 'package:life_os/features/tasks/presentation/tasks_screen.dart';
import 'package:life_os/features/calendar/presentation/calendar_screen.dart';
import 'package:life_os/features/splash/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provider to track the current and previous navigation index for transitions
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Global key used by the "+" nav button to trigger routine sheet on TasksScreen
final addRoutineNotifier = ValueNotifier<int>(0);

/// Global key used by the "+" nav button to trigger transaction sheet on FinanceScreen
final addTransactionNotifier = ValueNotifier<int>(0);

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(child: child),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            );
          },
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TasksScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/finance',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FinanceScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CalendarScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
          ),
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends HookConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    int getIndex() {
      if (location.startsWith('/tasks')) return 1;
      if (location.startsWith('/finance')) return 3;
      if (location.startsWith('/calendar')) return 4;
      return 0;
    }

    final currentIndex = getIndex();

    // Mapping for positions (0-4 items including the + button at 2)
    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        navIndex: 0,
      ),
      _NavItem(
        icon: Icons.event_repeat_outlined,
        activeIcon: Icons.event_repeat,
        label: 'Routines',
        navIndex: 1,
      ),
      const _NavItem(
        icon: Icons.add,
        activeIcon: Icons.add,
        label: '',
        navIndex: 2,
      ), // Placeholder for +
      _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Finance',
        navIndex: 3,
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: 'Calendar',
        navIndex: 4,
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 5;
                final pillPadding = 8.0;

                return Stack(
                  children: [
                    // Sliding background indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: currentIndex * itemWidth + pillPadding,
                      top: 4,
                      bottom: 4,
                      width: itemWidth - (pillPadding * 2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(
                            alpha: isDark ? 0.15 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    // Navbar items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(items.length, (i) {
                        final item = items[i];

                        // Special handling for the + button at index 2
                        if (i == 2) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _showAddChooser(context),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary,
                                      cs.primary.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        }

                        final isActive = currentIndex == item.navIndex;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (currentIndex == item.navIndex) return;
                              switch (item.navIndex) {
                                case 0:
                                  context.go('/');
                                  break;
                                case 1:
                                  context.go('/tasks');
                                  break;
                                case 3:
                                  context.go('/finance');
                                  break;
                                case 4:
                                  context.go('/calendar');
                                  break;
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: 24,
                                    color: isActive
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isActive
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddChooser(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create New',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Add Routine
              _AddChooserTile(
                icon: Icons.event_repeat,
                label: 'Add Routine',
                subtitle: 'Create a new daily habit or task',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/tasks');
                  // Small delay to let navigation complete
                  Future.delayed(const Duration(milliseconds: 150), () {
                    addRoutineNotifier.value++;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Add Transaction
              _AddChooserTile(
                icon: Icons.account_balance_wallet,
                label: 'Add Transaction',
                subtitle: 'Record income or expense',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/finance');
                  // Small delay to let navigation complete
                  Future.delayed(const Duration(milliseconds: 150), () {
                    addTransactionNotifier.value++;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddChooserTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddChooserTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int navIndex;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.navIndex,
  });
}
