import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rms_app/frontend/features/cashier_dashboard.dart';
import 'package:rms_app/frontend/screens/customer_screen.dart';
import 'package:rms_app/frontend/screens/employee_screen.dart';
import 'package:rms_app/frontend/features/admin_dashboard.dart';
import 'package:rms_app/frontend/core/app_shell.dart';
import 'package:rms_app/frontend/bloc/auth_bloc.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/core/injection.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';
import 'package:rms_app/frontend/screens/inventory_screen.dart';
import 'package:rms_app/frontend/screens/kicthen_screen.dart';
import 'package:rms_app/frontend/features/manager_dashboard.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:rms_app/frontend/screens/menu_screen.dart';
import 'package:rms_app/frontend/screens/order_screen.dart';
import 'package:rms_app/frontend/bloc/orders_bloc.dart';
import 'package:rms_app/frontend/screens/report_screen.dart';
import 'package:rms_app/frontend/screens/reservation_screen.dart';
import 'package:rms_app/frontend/screens/setting_screen.dart';
import 'package:rms_app/frontend/screens/table_screen.dart';
import 'package:rms_app/frontend/bloc/tables_bloc.dart';
import 'package:rms_app/frontend/screens/pos_screen.dart';


class AppRouter {
  static final _rootKey  = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final loc       = state.matchedLocation;
      final isLogin   = loc == '/login';

      if (authState is AuthLoading || authState is AuthInitial) return null;
      if (authState is AuthUnauthenticated && !isLogin)         return '/login';
      if (authState is AuthAuthenticated   &&  isLogin) {
        return _homeForRole(authState.user.role);
      }
      return null;
    },
    routes: [
      // ── Public ─────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Protected shell (sidebar + topbar) ─────────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [

          // Dashboards
          GoRoute(
            path: '/dashboard/admin',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<DashboardBloc>()..add(DashboardLoadEvent()),
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/manager',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<DashboardBloc>()..add(DashboardLoadEvent()),
              child: const ManagerDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/cashier',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<DashboardBloc>()..add(DashboardLoadEvent()),
              child: const CashierDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/kitchen',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<OrdersBloc>()..add(OrdersLoadEvent()),
              child: const KitchenScreen(),
            ),
          ),

          // Core screens
          GoRoute(
            path: '/tables',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<TablesBloc>()..add(TablesLoadEvent()),
              child: const TablesScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<OrdersBloc>()..add(OrdersLoadEvent()),
              child: const OrdersScreen(),
            ),
          ),
          GoRoute(
            path: '/menu',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<MenuBloc>()..add(MenuLoadEvent()),
              child: const MenuScreen(),
            ),
          ),
          GoRoute(
            path: '/pos',
            builder: (_, __) => const PosScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<InventoryBloc>()..add(InventoryLoadEvent()),
              child: const InventoryScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<CustomersBloc>()..add(CustomersLoadEvent()),
              child: const CustomersScreen(),
            ),
          ),
          GoRoute(
            path: '/reservations',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<ReservationsBloc>()..add(ReservationsLoadEvent()),
              child: const ReservationsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => BlocProvider(
              create: (_) => getIt<ReportsBloc>()..add(ReportsLoadEvent()),
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/employees',
            builder: (_, __) => const EmployeesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  static String _homeForRole(String role) => switch (role) {
    'admin'   => '/dashboard/admin',
    'manager' => '/dashboard/manager',
    'cashier' => '/pos',
    'kitchen' => '/kitchen',
    _         => '/dashboard/admin',
  };
}