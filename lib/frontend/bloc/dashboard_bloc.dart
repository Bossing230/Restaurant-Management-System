import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

// ════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════
class DashboardSummary extends Equatable {
  final double totalSales, salesChangePercent;
  final int totalOrders, pendingOrders, availableTables, occupiedTables, lowStockItems;

  const DashboardSummary({
    required this.totalSales,
    required this.salesChangePercent,
    required this.totalOrders,
    required this.pendingOrders,
    required this.availableTables,
    required this.occupiedTables,
    required this.lowStockItems,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    totalSales:          (j['total_sales']          as num).toDouble(),
    salesChangePercent:  (j['sales_change_percent'] as num?)?.toDouble() ?? 0,
    totalOrders:         (j['total_orders']         as num).toInt(),
    pendingOrders:       (j['pending_orders']       as num).toInt(),
    availableTables:     (j['available_tables']     as num?)?.toInt() ?? 0,
    occupiedTables:      (j['occupied_tables']      as num?)?.toInt() ?? 0,
    lowStockItems:       (j['low_stock_items']      as num).toInt(),
  );

  // Mock data shown when API is not available
  factory DashboardSummary.mock() => const DashboardSummary(
    totalSales: 24350, salesChangePercent: 18,
    totalOrders: 87, pendingOrders: 5,
    availableTables: 4, occupiedTables: 6, lowStockItems: 3,
  );

  @override
  List<Object?> get props => [totalSales, totalOrders];
}

class SalesPoint extends Equatable {
  final String label;
  final double amount;
  final int orderCount;
  const SalesPoint(this.label, this.amount, {this.orderCount = 0});
  @override List<Object?> get props => [label, amount];
}

class TopItem extends Equatable {
  final String name;
  final int quantitySold;
  final double revenue;
  const TopItem({required this.name, required this.quantitySold, required this.revenue});
  factory TopItem.fromJson(Map<String, dynamic> j) => TopItem(
    name:         j['name'] as String,
    quantitySold: int.parse(j['quantity_sold'].toString()),
    revenue:      double.parse(j['revenue'].toString()),
  );
  @override List<Object?> get props => [name, quantitySold];
}

class DashboardAlert extends Equatable {
  final String level, title, description;
  const DashboardAlert({required this.level, required this.title, required this.description});
  factory DashboardAlert.fromJson(Map<String, dynamic> j) => DashboardAlert(
    level:       j['type'] as String? ?? 'low',
    title:       j['title'] as String,
    description: j['description'] as String,
  );
  @override List<Object?> get props => [title];
}

class StaffMember extends Equatable {
  final String id, name, role, status;
  final int ordersHandled;
  final double salesAmount;
  const StaffMember({
    required this.id, required this.name, required this.role,
    required this.status, required this.ordersHandled, required this.salesAmount,
  });
  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
    id:            j['id'].toString(),
    name:          j['name'] as String,
    role:          j['role'] as String,
    status:        j['status'] as String,
    ordersHandled: int.parse((j['orders_handled'] ?? 0).toString()),
    salesAmount:   double.parse((j['sales_amount'] ?? 0).toString()),
  );
  String get initials => name.trim().split(' ').map((e) => e.isEmpty ? '' : e[0].toUpperCase()).take(2).join();
  @override List<Object?> get props => [id, status];
}

class RecentOrder extends Equatable {
  final String id, tableNo, status, type;
  final int itemCount;
  final double total;
  const RecentOrder({
    required this.id, required this.tableNo, required this.status,
    required this.type, required this.itemCount, required this.total,
  });
  factory RecentOrder.fromJson(Map<String, dynamic> j) => RecentOrder(
    id:        j['id'].toString(),
    tableNo:   j['table_number'] as String? ?? 'TO',
    status:    j['status'] as String,
    type:      j['order_type'] as String,
    itemCount: int.parse((j['item_count'] ?? 0).toString()),
    total:     double.parse(j['total'].toString()),
  );
  @override List<Object?> get props => [id];
}

// ════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════
abstract class DashboardEvent extends Equatable {
  @override List<Object?> get props => [];
}

class DashboardLoadEvent extends DashboardEvent {
  final String range;
  DashboardLoadEvent({this.range = 'weekly'});
  @override List<Object?> get props => [range];
}

class DashboardRefreshEvent extends DashboardEvent {}

// ════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════
abstract class DashboardState extends Equatable {
  @override List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final List<SalesPoint> salesData;
  final List<TopItem> topItems;
  final List<DashboardAlert> alerts;
  final List<StaffMember> staff;
  final List<RecentOrder> recentOrders;
  final String range;

  DashboardLoaded({
    required this.summary,
    required this.salesData,
    required this.topItems,
    required this.alerts,
    required this.staff,
    required this.recentOrders,
    required this.range,
  });

  @override
  List<Object?> get props => [summary, salesData, topItems, alerts, staff, range];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiClient _api;

  DashboardBloc({required ApiClient apiClient})
      : _api = apiClient,
        super(DashboardInitial()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardRefreshEvent>((_, emit) => _onLoad(DashboardLoadEvent(), emit));
  }

  Future<void> _onLoad(DashboardLoadEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      // Parallel API calls for performance
      final results = await Future.wait([
        _api.dio.get(ApiConstants.dashboardSummary),
        _api.dio.get(ApiConstants.dashboardSales, queryParameters: {'range': event.range}),
        _api.dio.get(ApiConstants.dashboardTopItems),
        _api.dio.get(ApiConstants.dashboardAlerts),
        _api.dio.get(ApiConstants.staff),
        _api.dio.get('${ApiConstants.orders}?limit=5'),
      ]);

      emit(DashboardLoaded(
        summary:      DashboardSummary.fromJson(results[0].data['data'] as Map<String, dynamic>),
        salesData:    (results[1].data['data'] as List<dynamic>).map((e) => SalesPoint(e['label'] as String, double.parse(e['amount'].toString()), orderCount: int.parse((e['order_count'] ?? 0).toString()))).toList(),
        topItems:     (results[2].data['data'] as List<dynamic>).map((e) => TopItem.fromJson(e as Map<String, dynamic>)).toList(),
        alerts:       (results[3].data['data'] as List<dynamic>).map((e) => DashboardAlert.fromJson(e as Map<String, dynamic>)).toList(),
        staff:        (results[4].data['data'] as List<dynamic>).map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).toList(),
        recentOrders: (results[5].data['data'] as List<dynamic>).map((e) => RecentOrder.fromJson(e as Map<String, dynamic>)).toList(),
        range:        event.range,
      ));
    } catch (_) {
      // Fall back to mock data so the app works without a backend
      emit(DashboardLoaded(
        summary: DashboardSummary.mock(),
        salesData: const [
          SalesPoint('Mon', 8200,  orderCount: 32),
          SalesPoint('Tue', 11400, orderCount: 45),
          SalesPoint('Wed', 9700,  orderCount: 38),
          SalesPoint('Thu', 13500, orderCount: 52),
          SalesPoint('Fri', 10200, orderCount: 40),
          SalesPoint('Sat', 14800, orderCount: 58),
          SalesPoint('Sun', 7600,  orderCount: 30),
        ],
        topItems: const [
          TopItem(name: 'Beef Sinigang',  quantitySold: 48, revenue: 8880),
          TopItem(name: 'Chicken Adobo', quantitySold: 41, revenue: 6765),
          TopItem(name: 'Pork Sisig',    quantitySold: 37, revenue: 6475),
          TopItem(name: 'Halo-Halo',     quantitySold: 35, revenue: 3325),
          TopItem(name: 'Pancit Canton', quantitySold: 29, revenue: 4205),
        ],
        alerts: const [
          DashboardAlert(level: 'high',   title: 'Low stock: Pork',        description: '3 kg remaining — below 20% threshold'),
          DashboardAlert(level: 'high',   title: 'Low stock: Coconut Milk',description: '2 cans remaining'),
          DashboardAlert(level: 'medium', title: 'Peak volume alert',      description: '87 orders today'),
          DashboardAlert(level: 'low',    title: '2 staff on break',       description: 'Kitchen coverage may be reduced'),
        ],
        staff: const [
          StaffMember(id: '1', name: 'Maria Santos', role: 'Cashier', status: 'online', ordersHandled: 14, salesAmount: 6840),
          StaffMember(id: '2', name: 'Jose Reyes',   role: 'Waiter',  status: 'online', ordersHandled: 22, salesAmount: 9020),
          StaffMember(id: '3', name: 'Ana Cruz',     role: 'Kitchen', status: 'break',  ordersHandled: 0,  salesAmount: 0),
          StaffMember(id: '4', name: 'Liza Garcia',  role: 'Cashier', status: 'online', ordersHandled: 9,  salesAmount: 3780),
        ],
        recentOrders: const [
          RecentOrder(id: '101', tableNo: 'T3', status: 'Preparing', type: 'Dine-in',  itemCount: 3, total: 532),
          RecentOrder(id: '102', tableNo: 'T7', status: 'Pending',   type: 'Takeout',  itemCount: 2, total: 370),
          RecentOrder(id: '103', tableNo: 'T1', status: 'Ready',     type: 'Dine-in',  itemCount: 4, total: 680),
          RecentOrder(id: '104', tableNo: 'TO', status: 'Completed', type: 'Delivery', itemCount: 2, total: 392),
        ],
        range: event.range,
      ));
    }
  }
}