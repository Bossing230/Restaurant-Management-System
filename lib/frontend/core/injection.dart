import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:rms_app/frontend/bloc/auth_bloc.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:rms_app/frontend/bloc/orders_bloc.dart';
import 'package:rms_app/frontend/bloc/pos_bloc.dart';
import 'package:rms_app/frontend/bloc/tables_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Core singletons ────────────────────────────────────────
  getIt.registerSingleton<Logger>(
    Logger(printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5)),
  );

  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  getIt.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );

  getIt.registerSingleton<ApiClient>(
    ApiClient(getIt<FlutterSecureStorage>(), getIt<Logger>()),
  );

  // ── Feature BLoCs (factory = new instance per screen) ──────
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(apiClient: getIt(), storage: getIt()),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(apiClient: getIt()),
  );
  getIt.registerFactory<TablesBloc>(
    () => TablesBloc(apiClient: getIt()),
  );
  getIt.registerFactory<OrdersBloc>(
    () => OrdersBloc(apiClient: getIt()),
  );
  getIt.registerFactory<MenuBloc>(
    () => MenuBloc(apiClient: getIt()),
  );
  getIt.registerFactory<PosBloc>(
    () => PosBloc(apiClient: getIt()),
  );
  getIt.registerFactory<InventoryBloc>(
    () => InventoryBloc(apiClient: getIt()),
  );
  getIt.registerFactory<CustomersBloc>(
    () => CustomersBloc(apiClient: getIt()),
  );
  getIt.registerFactory<ReservationsBloc>(
    () => ReservationsBloc(apiClient: getIt()),
  );
  getIt.registerFactory<ReportsBloc>(
    () => ReportsBloc(apiClient: getIt()),
  );
}