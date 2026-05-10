import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_router.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/bloc/auth_bloc.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:rms_app/frontend/bloc/pos_bloc.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';
import 'package:rms_app/frontend/bloc/orders_bloc.dart';
import 'package:rms_app/frontend/bloc/tables_bloc.dart';
import 'package:rms_app/frontend/core/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckEvent()),
        ),
        BlocProvider<MenuBloc>(
          create: (_) => getIt<MenuBloc>()..add(MenuLoadEvent()),
        ),
        BlocProvider<PosBloc>(
          create: (_) => getIt<PosBloc>(),
        ),
        BlocProvider<DashboardBloc>(
          create: (_) => getIt<DashboardBloc>(),
        ),
        BlocProvider<InventoryBloc>(
          create: (_) => getIt<InventoryBloc>(),
        ),
        BlocProvider<OrdersBloc>(
          create: (_) => getIt<OrdersBloc>(),
        ),
        BlocProvider<TablesBloc>(
          create: (_) => getIt<TablesBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Boba App',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}