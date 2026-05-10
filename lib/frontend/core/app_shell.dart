import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rms_app/frontend/bloc/auth_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Builder(
        builder: (context) {
          final width = MediaQuery.of(context).size.width;
          final isTablet = width >= 768;
          final isDesktop = width >= 1100;

          if (isTablet) {
            return Scaffold(
              body: Row(
                children: [
                  _Sidebar(location: location, collapsed: !isDesktop),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(location: location),
                        Expanded(child: child), // This child is your PosScreen
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            drawer: Drawer(
              backgroundColor: AppColors.bgSidebar,
              child: _SidebarContent(location: location, collapsed: false),
            ),
            body: Column(
              children: [
                _TopBar(location: location, showMenu: true),
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Sidebar wrapper with animated width ─────────────────────
class _Sidebar extends StatelessWidget {
  final String location;
  final bool collapsed;
  const _Sidebar({required this.location, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: collapsed ? 68 : 240,
      child: _SidebarContent(location: location, collapsed: collapsed),
    );
  }
}

// ─── Sidebar content ─────────────────────────────────────────
class _SidebarContent extends StatelessWidget {
  final String location;
  final bool collapsed;
  const _SidebarContent({required this.location, required this.collapsed});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? 'admin';
    final items = _navItems(role);

    return Container(
      color: AppColors.bgSidebar,
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 12),
          // Logo
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 18),
            alignment: collapsed ? Alignment.center : Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: collapsed
              ? Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                )
              : Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text('Boba Food', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text('Food for everybody', style: AppText.small.copyWith(fontSize: 10)),
                  ]),
                ]),
          ),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 6 : 10, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.isDivider) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: AppColors.border),
                  );
                }
                final active = location.startsWith(item.route ?? '___');
                return _NavItem(
                  item: item,
                  active: active,
                  collapsed: collapsed,
                  onTap: () {
                    if (item.route != null) context.go(item.route!);
                    if (!collapsed) Navigator.of(context).maybePop();
                  },
                );
              },
            ),
          ),

          // Logout button (instead of user info)
          Container(
            padding: EdgeInsets.all(collapsed ? 8 : 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: collapsed
              ? Tooltip(
                  message: 'Logout',
                  child: IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: AppColors.danger),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
          ),
        ]),
      ),
    );
  }

  List<_NavItemData> _navItems(String role) => switch (role) {
    'admin' => [
      _NavItemData(icon: Icons.dashboard_outlined,      label: 'Dashboard',  route: '/dashboard/admin'),
      _NavItemData(icon: Icons.people_outline,           label: 'Employees',  route: '/employees'),
      _NavItemData(icon: Icons.inventory_2_outlined,     label: 'Inventory',  route: '/inventory'),
      _NavItemData(icon: Icons.restaurant_menu_outlined, label: 'Menu',       route: '/menu'),
      _NavItemData(icon: Icons.bar_chart_outlined,       label: 'Reports',    route: '/reports'),
      _NavItemData(isDivider: true),
      _NavItemData(icon: Icons.settings_outlined,        label: 'Settings',   route: '/settings'),
    ],
    'manager' => [
      _NavItemData(icon: Icons.dashboard_outlined,       label: 'Dashboard',     route: '/dashboard/manager'),
      _NavItemData(icon: Icons.table_restaurant_outlined,label: 'Tables',        route: '/tables'),
      _NavItemData(icon: Icons.receipt_long_outlined,    label: 'Orders',        route: '/orders'),
      _NavItemData(icon: Icons.calendar_today_outlined,  label: 'Reservations',  route: '/reservations'),
      _NavItemData(icon: Icons.inventory_2_outlined,     label: 'Inventory',     route: '/inventory'),
      _NavItemData(icon: Icons.people_outline,           label: 'Employees',     route: '/employees'),
    ],
    'cashier' => [
      _NavItemData(icon: Icons.point_of_sale_outlined,   label: 'POS',           route: '/pos'),
      _NavItemData(icon: Icons.receipt_long_outlined,    label: 'Orders',        route: '/orders'),
      _NavItemData(icon: Icons.table_restaurant_outlined,label: 'Tables',        route: '/tables'),
      _NavItemData(icon: Icons.dashboard_outlined,       label: 'Summary',       route: '/dashboard/cashier'),
    ],
    'kitchen' => [
      _NavItemData(icon: Icons.soup_kitchen_outlined,    label: 'Kitchen Display', route: '/kitchen'),
      _NavItemData(icon: Icons.check_circle_outline,     label: 'Completed',       route: '/orders'),
    ],
    _ => [],
  };
}

// ─── Single nav item ─────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool active, collapsed;
  final VoidCallback onTap;
  const _NavItem({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon, size: 18,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (active)
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String? route;
  final bool isDivider;
  const _NavItemData({
    this.icon = Icons.circle,
    this.label = '',
    this.route,
    this.isDivider = false,
  });
}

// ─── Top bar ─────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String location;
  final bool showMenu;
  const _TopBar({required this.location, this.showMenu = false});

  String _title(String loc) {
    if (loc.contains('admin'))        return 'Admin Dashboard';
    if (loc.contains('manager'))      return 'Manager Dashboard';
    if (loc.contains('cashier'))      return 'Cashier Dashboard';
    if (loc.contains('kitchen'))      return 'Kitchen Display';
    if (loc.contains('tables'))       return 'Tables';
    if (loc.contains('orders'))       return 'Orders';
    if (loc.contains('menu'))         return 'Menu';
    if (loc.contains('pos'))          return 'Point of Sale';
    if (loc.contains('inventory'))    return 'Inventory';
    if (loc.contains('customers'))    return 'Customers';
    if (loc.contains('reservations')) return 'Reservations';
    if (loc.contains('reports'))      return 'Reports';
    if (loc.contains('employees'))    return 'Employees';
    if (loc.contains('settings'))     return 'Settings';
    return 'RestaurantOS';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        if (showMenu)
          IconButton(
            icon: const Icon(Icons.menu, size: 20),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        Text(_title(location), style: AppText.h4),
        const Spacer(),
        // Notification bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20,
                  color: AppColors.textSecondary),
              onPressed: () {},
            ),
            Positioned(
              right: 8, top: 8,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        UserAvatar(name: user?.name ?? 'User', size: 34),
        const SizedBox(width: 6),
        const Icon(Icons.keyboard_arrow_down, size: 16,
            color: AppColors.textSecondary),
      ]),
    );
  }
}