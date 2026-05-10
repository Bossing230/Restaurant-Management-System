import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

class InventoryItem extends Equatable {
  final String id, name, category, unit;
  final double stock, maxStock, minStock;
  double get pct    => maxStock > 0 ? stock / maxStock : 0;
  bool   get isLow  => pct < 0.3;

  const InventoryItem({
    required this.id, required this.name, required this.category,
    required this.unit, required this.stock,
    required this.maxStock, required this.minStock,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    id:       j['id'].toString(),
    name:     j['name']     as String,
    category: j['category'] as String,
    unit:     j['unit']     as String,
    stock:    double.parse(j['stock'].toString()),
    maxStock: double.parse(j['max_stock'].toString()),
    minStock: double.parse((j['min_stock'] ?? 0).toString()),
  );

  InventoryItem copyWith({double? stock}) => InventoryItem(
    id: id, name: name, category: category, unit: unit,
    stock: stock ?? this.stock, maxStock: maxStock, minStock: minStock,
  );

  @override List<Object?> get props => [id, stock];
}

abstract class InventoryEvent extends Equatable { @override List<Object?> get props => []; }
class InventoryLoadEvent     extends InventoryEvent {}
class InventoryRefreshEvent  extends InventoryEvent {}
class InventoryRestockEvent  extends InventoryEvent {
  final String id;
  InventoryRestockEvent(this.id);
  @override List<Object?> get props => [id];
}
class InventoryRestockAllEvent extends InventoryEvent {}

abstract class InventoryState extends Equatable { @override List<Object?> get props => []; }
class InventoryLoading extends InventoryState {}
class InventoryLoaded  extends InventoryState {
  final List<InventoryItem> items;
  InventoryLoaded(this.items);
  List<InventoryItem> get lowItems => items.where((i) => i.isLow).toList();
  InventoryLoaded copyWith({List<InventoryItem>? items}) => InventoryLoaded(items ?? this.items);
  @override List<Object?> get props => [items];
}
class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
  @override List<Object?> get props => [message];
}

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiClient _api;

  InventoryBloc({required ApiClient apiClient})
      : _api = apiClient, super(InventoryLoading()) {
    on<InventoryLoadEvent>(_onLoad);
    on<InventoryRefreshEvent>((_, emit) => _onLoad(InventoryLoadEvent(), emit));
    on<InventoryRestockEvent>(_onRestock);
    on<InventoryRestockAllEvent>(_onRestockAll);
  }

  Future<void> _onLoad(InventoryLoadEvent _, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final res = await _api.dio.get(ApiConstants.inventory);
      emit(InventoryLoaded(
        (res.data['data'] as List<dynamic>).map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    } catch (_) {
      emit(InventoryLoaded(_mock));
    }
  }

  void _onRestock(InventoryRestockEvent e, Emitter<InventoryState> emit) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    final item = s.items.firstWhere((i) => i.id == e.id);
    emit(s.copyWith(
      items: s.items.map((i) =>
        i.id == e.id ? i.copyWith(stock: i.maxStock) : i
      ).toList(),
    ));
    try {
      _api.dio.put('${ApiConstants.inventory}/${e.id}', data: {'stock': item.maxStock});
    } catch (_) {}
  }

  void _onRestockAll(InventoryRestockAllEvent _, Emitter<InventoryState> emit) {
    if (state is! InventoryLoaded) return;
    final s = state as InventoryLoaded;
    emit(s.copyWith(
      items: s.items.map((i) => i.isLow ? i.copyWith(stock: i.maxStock) : i).toList(),
    ));
  }

  static final _mock = [
    const InventoryItem(id:'1', name:'Beef',        category:'Meat',    unit:'kg',   stock:12, maxStock:30, minStock:5),
    const InventoryItem(id:'2', name:'Chicken',     category:'Meat',    unit:'kg',   stock:8,  maxStock:25, minStock:5),
    const InventoryItem(id:'3', name:'Pork',        category:'Meat',    unit:'kg',   stock:3,  maxStock:20, minStock:5),
    const InventoryItem(id:'4', name:'Rice',        category:'Grains',  unit:'kg',   stock:45, maxStock:50, minStock:10),
    const InventoryItem(id:'5', name:'Coconut Milk',category:'Pantry',  unit:'cans', stock:2,  maxStock:10, minStock:3),
    const InventoryItem(id:'6', name:'Vegetables',  category:'Produce', unit:'kg',   stock:6,  maxStock:15, minStock:4),
    const InventoryItem(id:'7', name:'Soy Sauce',   category:'Pantry',  unit:'btl',  stock:4,  maxStock:8,  minStock:2),
    const InventoryItem(id:'8', name:'Sugar',       category:'Pantry',  unit:'kg',   stock:18, maxStock:25, minStock:5),
  ];
}

// ════════════════════════════════════════════════════════════
// CUSTOMERS BLOC
// ════════════════════════════════════════════════════════════
class CustomerModel extends Equatable {
  final String id, name;
  final String? email, phone;
  final int loyaltyPoints, totalOrders;
  final double totalSpent;
  final DateTime? lastVisit;

  const CustomerModel({
    required this.id, required this.name,
    this.email, this.phone,
    this.loyaltyPoints = 0, this.totalOrders = 0,
    this.totalSpent = 0, this.lastVisit,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
    id:            j['id'].toString(),
    name:          j['name'] as String,
    email:         j['email'] as String?,
    phone:         j['phone'] as String?,
    loyaltyPoints: int.parse((j['loyalty_points'] ?? 0).toString()),
    totalOrders:   int.parse((j['total_orders']   ?? 0).toString()),
    totalSpent:    double.parse((j['total_spent']  ?? 0).toString()),
    lastVisit:     j['last_visit'] != null
        ? DateTime.tryParse(j['last_visit'] as String) : null,
  );

  String get initials => name.trim().split(' ')
      .map((e) => e.isEmpty ? '' : e[0].toUpperCase()).take(2).join();

  @override List<Object?> get props => [id];
}

abstract class CustomersEvent extends Equatable { @override List<Object?> get props => []; }
class CustomersLoadEvent   extends CustomersEvent {}
class CustomersSearchEvent extends CustomersEvent {
  final String query;
  CustomersSearchEvent(this.query);
  @override List<Object?> get props => [query];
}

abstract class CustomersState extends Equatable { @override List<Object?> get props => []; }
class CustomersLoading extends CustomersState {}
class CustomersLoaded  extends CustomersState {
  final List<CustomerModel> all, filtered;
  CustomersLoaded({required this.all, required this.filtered});
  CustomersLoaded copyWith({List<CustomerModel>? all, List<CustomerModel>? filtered}) =>
      CustomersLoaded(all: all ?? this.all, filtered: filtered ?? this.filtered);
  @override List<Object?> get props => [all, filtered];
}
class CustomersError extends CustomersState {
  final String message;
  CustomersError(this.message);
  @override List<Object?> get props => [message];
}

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final ApiClient _api;
  List<CustomerModel> _all = [];

  CustomersBloc({required ApiClient apiClient})
      : _api = apiClient, super(CustomersLoading()) {
    on<CustomersLoadEvent>(_onLoad);
    on<CustomersSearchEvent>(_onSearch);
  }

  Future<void> _onLoad(CustomersLoadEvent _, Emitter<CustomersState> emit) async {
    emit(CustomersLoading());
    try {
      final res = await _api.dio.get(ApiConstants.customers);
      _all = (res.data['data'] as List<dynamic>).map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      emit(CustomersLoaded(all: _all, filtered: _all));
    } catch (_) {
      _all = _mock;
      emit(CustomersLoaded(all: _all, filtered: _all));
    }
  }

  void _onSearch(CustomersSearchEvent e, Emitter<CustomersState> emit) {
    if (state is! CustomersLoaded) return;
    final q = e.query.toLowerCase().trim();
    emit((state as CustomersLoaded).copyWith(
      filtered: q.isEmpty ? _all : _all.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.email?.toLowerCase().contains(q) ?? false) ||
        (c.phone?.contains(q) ?? false)
      ).toList(),
    ));
  }

  static final _mock = [
    const CustomerModel(id:'1', name:'Maria Santos',   email:'maria@email.com',  phone:'+63 917 123 4567', loyaltyPoints:467, totalOrders:23, totalSpent:4670),
    const CustomerModel(id:'2', name:'Jose Reyes',     email:'jose@email.com',   phone:'+63 918 987 6543', loyaltyPoints:234, totalOrders:12, totalSpent:2340),
    const CustomerModel(id:'3', name:'Ana Cruz',       email:'ana@email.com',    phone:'+63 919 555 0001', loyaltyPoints:385, totalOrders:19, totalSpent:3850),
    const CustomerModel(id:'4', name:'Pedro Bautista', email:'pedro@email.com',  phone:'+63 920 444 0002', loyaltyPoints:118, totalOrders:7,  totalSpent:1180),
    const CustomerModel(id:'5', name:'Liza Garcia',    email:'liza@email.com',   phone:'+63 921 333 0003', loyaltyPoints:92,  totalOrders:5,  totalSpent:920),
    const CustomerModel(id:'6', name:'Rosa Dela Cruz', email:'rosa@email.com',   phone:'+63 922 222 0004', loyaltyPoints:310, totalOrders:16, totalSpent:3100),
  ];
}

// ════════════════════════════════════════════════════════════
// RESERVATIONS BLOC
// ════════════════════════════════════════════════════════════
class ReservationModel extends Equatable {
  final String id, status;
  final String? customerName, customerPhone, tableNumber, notes;
  final DateTime reservedAt;
  final int partySize;

  const ReservationModel({
    required this.id, required this.status, required this.reservedAt,
    required this.partySize,
    this.customerName, this.customerPhone, this.tableNumber, this.notes,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> j) => ReservationModel(
    id:            j['id'].toString(),
    status:        j['status'] as String,
    reservedAt:    DateTime.parse(j['reserved_at'] as String),
    partySize:     j['party_size'] as int? ?? 2,
    customerName:  j['customer_name']  as String?,
    customerPhone: j['customer_phone'] as String?,
    tableNumber:   j['table_number']   as String?,
    notes:         j['notes']          as String?,
  );

  ReservationModel copyWith({String? status}) => ReservationModel(
    id: id, status: status ?? this.status, reservedAt: reservedAt,
    partySize: partySize, customerName: customerName,
    customerPhone: customerPhone, tableNumber: tableNumber, notes: notes,
  );

  @override List<Object?> get props => [id, status];
}

abstract class ReservationsEvent extends Equatable { @override List<Object?> get props => []; }
class ReservationsLoadEvent   extends ReservationsEvent {
  final String filter;
  ReservationsLoadEvent({this.filter = 'today'});
  @override List<Object?> get props => [filter];
}
class ReservationsSetFilterEvent extends ReservationsEvent {
  final String filter;
  ReservationsSetFilterEvent(this.filter);
  @override List<Object?> get props => [filter];
}
class ReservationsUpdateStatusEvent extends ReservationsEvent {
  final String id, status;
  ReservationsUpdateStatusEvent(this.id, this.status);
  @override List<Object?> get props => [id, status];
}

abstract class ReservationsState extends Equatable { @override List<Object?> get props => []; }
class ReservationsLoading extends ReservationsState {}
class ReservationsLoaded  extends ReservationsState {
  final List<ReservationModel> reservations;
  final String activeFilter;
  ReservationsLoaded({required this.reservations, this.activeFilter = 'today'});
  ReservationsLoaded copyWith({List<ReservationModel>? reservations, String? activeFilter}) =>
      ReservationsLoaded(
        reservations: reservations ?? this.reservations,
        activeFilter: activeFilter ?? this.activeFilter,
      );
  @override List<Object?> get props => [reservations, activeFilter];
}
class ReservationsError extends ReservationsState {
  final String message;
  ReservationsError(this.message);
  @override List<Object?> get props => [message];
}

class ReservationsBloc extends Bloc<ReservationsEvent, ReservationsState> {
  final ApiClient _api;

  ReservationsBloc({required ApiClient apiClient})
      : _api = apiClient, super(ReservationsLoading()) {
    on<ReservationsLoadEvent>(_onLoad);
    on<ReservationsSetFilterEvent>((e, emit) {
      if (state is ReservationsLoaded) {
        emit((state as ReservationsLoaded).copyWith(activeFilter: e.filter));
      }
    });
    on<ReservationsUpdateStatusEvent>(_onUpdate);
  }

  Future<void> _onLoad(ReservationsLoadEvent e, Emitter<ReservationsState> emit) async {
    emit(ReservationsLoading());
    try {
      final params = e.filter == 'today'
          ? {'date': DateTime.now().toIso8601String().substring(0, 10)}
          : <String, dynamic>{};
      final res = await _api.dio.get(ApiConstants.reservations, queryParameters: params);
      emit(ReservationsLoaded(
        reservations: (res.data['data'] as List<dynamic>).map((e) => ReservationModel.fromJson(e as Map<String, dynamic>)).toList(),
        activeFilter: e.filter,
      ));
    } catch (_) {
      emit(ReservationsLoaded(reservations: _mock, activeFilter: e.filter));
    }
  }

  void _onUpdate(ReservationsUpdateStatusEvent e, Emitter<ReservationsState> emit) {
    if (state is! ReservationsLoaded) return;
    final s = state as ReservationsLoaded;
    emit(s.copyWith(
      reservations: s.reservations.map((r) =>
        r.id == e.id ? r.copyWith(status: e.status) : r
      ).toList(),
    ));
    try {
      _api.dio.put('${ApiConstants.reservations}/${e.id}/status', data: {'status': e.status});
    } catch (_) {}
  }

  static final _mock = [
    ReservationModel(id:'1', status:'confirmed', reservedAt: DateTime.now().add(const Duration(hours:2)),   partySize:4, customerName:'Maria Santos',   customerPhone:'+63 917 123 4567', tableNumber:'T3', notes:'Birthday celebration'),
    ReservationModel(id:'2', status:'confirmed', reservedAt: DateTime.now().add(const Duration(hours:4)),   partySize:2, customerName:'Jose Reyes',     customerPhone:'+63 918 987 6543', tableNumber:'T2'),
    ReservationModel(id:'3', status:'seated',    reservedAt: DateTime.now().subtract(const Duration(minutes:20)), partySize:6, customerName:'Ana Cruz',  customerPhone:'+63 919 555 0001', tableNumber:'T6', notes:'Window seat'),
    ReservationModel(id:'4', status:'confirmed', reservedAt: DateTime.now().add(const Duration(hours:5)),   partySize:8, customerName:'Pedro Bautista', tableNumber:'T8', notes:'Anniversary dinner'),
    ReservationModel(id:'5', status:'cancelled', reservedAt: DateTime.now().add(const Duration(hours:3)),   partySize:3, customerName:'Liza Garcia',    tableNumber:'T4'),
  ];
}

// ════════════════════════════════════════════════════════════
// REPORTS BLOC
// ════════════════════════════════════════════════════════════
class SalesPoint extends Equatable {
  final String label;
  final double amount;
  final int orderCount;
  const SalesPoint(this.label, this.amount, {this.orderCount = 0});
  @override List<Object?> get props => [label, amount];
}

class ReportTopItem extends Equatable {
  final String name;
  final int quantitySold;
  final double revenue;
  const ReportTopItem({required this.name, required this.quantitySold, required this.revenue});
  factory ReportTopItem.fromJson(Map<String, dynamic> j) => ReportTopItem(
    name:         j['name'] as String,
    quantitySold: int.parse(j['quantity_sold'].toString()),
    revenue:      double.parse(j['revenue'].toString()),
  );
  @override List<Object?> get props => [name, quantitySold];
}

abstract class ReportsEvent extends Equatable { @override List<Object?> get props => []; }
class ReportsLoadEvent extends ReportsEvent {
  final String range;
  ReportsLoadEvent({this.range = 'weekly'});
  @override List<Object?> get props => [range];
}

abstract class ReportsState extends Equatable { @override List<Object?> get props => []; }
class ReportsLoading extends ReportsState {}
class ReportsLoaded  extends ReportsState {
  final List<SalesPoint> sales;
  final List<ReportTopItem> topItems;
  final double totalRevenue, avgOrderValue;
  final int totalOrders;
  final String range;

  ReportsLoaded({
    required this.sales, required this.topItems,
    required this.totalRevenue, required this.avgOrderValue,
    required this.totalOrders, required this.range,
  });
  @override List<Object?> get props => [sales, topItems, totalRevenue, range];
}
class ReportsError extends ReportsState {
  final String message;
  ReportsError(this.message);
  @override List<Object?> get props => [message];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ApiClient _api;

  ReportsBloc({required ApiClient apiClient})
      : _api = apiClient, super(ReportsLoading()) {
    on<ReportsLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(ReportsLoadEvent e, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final results = await Future.wait([
        _api.dio.get(ApiConstants.salesReport,    queryParameters: {'range': e.range}),
        _api.dio.get(ApiConstants.topItems),
        _api.dio.get(ApiConstants.reportsSummary),
      ]);
      final sales  = (results[0].data['data'] as List<dynamic>).map((s) => SalesPoint(s['label'] as String, double.parse(s['amount'].toString()), orderCount: int.parse((s['order_count'] ?? 0).toString()))).toList();
      final tops   = (results[1].data['data'] as List<dynamic>).map((e) => ReportTopItem.fromJson(e as Map<String, dynamic>)).toList();
      final sum    = results[2].data['data'] as Map<String, dynamic>;
      final total  = double.parse(sum['total_revenue'].toString());
      final orders = int.parse(sum['total_orders'].toString());
      emit(ReportsLoaded(
        sales: sales, topItems: tops,
        totalRevenue: total, avgOrderValue: orders > 0 ? total / orders : 0,
        totalOrders: orders, range: e.range,
      ));
    } catch (_) {
      const mockSales = [
        SalesPoint('Mon', 8200,  orderCount:32), SalesPoint('Tue', 11400, orderCount:45),
        SalesPoint('Wed', 9700,  orderCount:38), SalesPoint('Thu', 13500, orderCount:52),
        SalesPoint('Fri', 10200, orderCount:40), SalesPoint('Sat', 14800, orderCount:58),
        SalesPoint('Sun', 7600,  orderCount:30),
      ];
      const total = 75400.0;
      emit(ReportsLoaded(
        sales: mockSales,
        topItems: const [
          ReportTopItem(name:'Beef Sinigang',  quantitySold:48, revenue:8880),
          ReportTopItem(name:'Chicken Adobo',  quantitySold:41, revenue:6765),
          ReportTopItem(name:'Pork Sisig',     quantitySold:37, revenue:6475),
          ReportTopItem(name:'Halo-Halo',      quantitySold:35, revenue:3325),
          ReportTopItem(name:'Pancit Canton',  quantitySold:29, revenue:4205),
        ],
        totalRevenue: total,
        avgOrderValue: total / 295,
        totalOrders: 295,
        range: e.range,
      ));
    }
  }
}