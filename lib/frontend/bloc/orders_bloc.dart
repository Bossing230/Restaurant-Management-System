import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

class OrderModel extends Equatable {
  final String id, status, type, paymentMethod;
  final String? tableNumber, createdByName;
  final List<Map<String, dynamic>> items;
  final double subtotal, tax, total;
  final DateTime createdAt;

  const OrderModel({
    required this.id, required this.status, required this.type,
    required this.paymentMethod, required this.items,
    required this.subtotal, required this.tax, required this.total,
    required this.createdAt, this.tableNumber, this.createdByName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:            j['id'].toString(),
    status:        j['status'] as String,
    type:          j['order_type'] as String,
    paymentMethod: j['payment_method'] as String,
    items:         List<Map<String, dynamic>>.from(j['items'] as List? ?? []),
    subtotal:      double.parse((j['subtotal'] ?? 0).toString()),
    tax:           double.parse((j['tax']      ?? 0).toString()),
    total:         double.parse(j['total'].toString()),
    createdAt:     DateTime.parse(j['created_at'] as String),
    tableNumber:   j['table_number'] as String?,
    createdByName: j['created_by_name'] as String?,
  );

  OrderModel copyWith({String? status}) => OrderModel(
    id: id, status: status ?? this.status, type: type,
    paymentMethod: paymentMethod, items: items,
    subtotal: subtotal, tax: tax, total: total,
    createdAt: createdAt, tableNumber: tableNumber, createdByName: createdByName,
  );

  int get minutesAgo => DateTime.now().difference(createdAt).inMinutes;
  bool get isUrgent  => status == 'Pending' && minutesAgo > 15;

  @override List<Object?> get props => [id, status];
}

// Events
abstract class OrdersEvent extends Equatable { @override List<Object?> get props => []; }
class OrdersLoadEvent extends OrdersEvent {}
class OrdersRefreshEvent extends OrdersEvent {}
class OrdersSetFilterEvent extends OrdersEvent {
  final String filter;
  OrdersSetFilterEvent(this.filter);
  @override List<Object?> get props => [filter];
}
class OrdersUpdateStatusEvent extends OrdersEvent {
  final String id, status;
  OrdersUpdateStatusEvent(this.id, this.status);
  @override List<Object?> get props => [id, status];
}

// States
abstract class OrdersState extends Equatable { @override List<Object?> get props => []; }
class OrdersLoading extends OrdersState {}
class OrdersLoaded extends OrdersState {
  final List<OrderModel> all;
  final String activeFilter;
  OrdersLoaded({required this.all, this.activeFilter = 'All'});
  List<OrderModel> get filtered => activeFilter == 'All'
      ? all : all.where((o) => o.status == activeFilter).toList();
  OrdersLoaded copyWith({List<OrderModel>? all, String? activeFilter}) =>
      OrdersLoaded(all: all ?? this.all, activeFilter: activeFilter ?? this.activeFilter);
  @override List<Object?> get props => [all, activeFilter];
}
class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiClient _api;

  OrdersBloc({required ApiClient apiClient})
      : _api = apiClient, super(OrdersLoading()) {
    on<OrdersLoadEvent>(_onLoad);
    on<OrdersRefreshEvent>((_, emit) => _onLoad(OrdersLoadEvent(), emit));
    on<OrdersSetFilterEvent>((e, emit) {
      if (state is OrdersLoaded) {
        emit((state as OrdersLoaded).copyWith(activeFilter: e.filter));
      }
    });
    on<OrdersUpdateStatusEvent>(_onUpdate);
  }

  Future<void> _onLoad(OrdersLoadEvent _, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    try {
      final res = await _api.dio.get(ApiConstants.orders);
      emit(OrdersLoaded(
        all: (res.data['data'] as List<dynamic>).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    } catch (_) {
      emit(OrdersLoaded(all: _mockOrders));
    }
  }

  Future<void> _onUpdate(OrdersUpdateStatusEvent e, Emitter<OrdersState> emit) async {
    if (state is! OrdersLoaded) return;
    final s = state as OrdersLoaded;
    emit(s.copyWith(
      all: s.all.map((o) => o.id == e.id ? o.copyWith(status: e.status) : o).toList(),
    ));
    try {
      await _api.dio.put('${ApiConstants.orders}/${e.id}/status', data: {'status': e.status});
    } catch (_) {}
  }

  static final _mockOrders = [
    OrderModel(id:'101', status:'Preparing', type:'Dine-in',  paymentMethod:'Cash',
      items:[{'name':'Beef Sinigang','qty':1},{'name':'Pancit Canton','qty':2}],
      subtotal:475, tax:57, total:532, tableNumber:'T3',
      createdAt: DateTime.now().subtract(const Duration(minutes:12))),
    OrderModel(id:'102', status:'Pending',   type:'Takeout',  paymentMethod:'Card',
      items:[{'name':'Chicken Adobo','qty':2}],
      subtotal:330, tax:39.6, total:369.6,
      createdAt: DateTime.now().subtract(const Duration(minutes:5))),
    OrderModel(id:'103', status:'Ready',     type:'Dine-in',  paymentMethod:'Cash',
      items:[{'name':'Kare-Kare','qty':1},{'name':'Leche Flan','qty':2}],
      subtotal:370, tax:44.4, total:414.4, tableNumber:'T1',
      createdAt: DateTime.now().subtract(const Duration(minutes:28))),
    OrderModel(id:'104', status:'Completed', type:'Delivery', paymentMethod:'E-wallet',
      items:[{'name':'Pork Sisig','qty':2}],
      subtotal:350, tax:42, total:392,
      createdAt: DateTime.now().subtract(const Duration(hours:1))),
    OrderModel(id:'105', status:'Pending',   type:'Dine-in',  paymentMethod:'Cash',
      items:[{'name':'Halo-Halo','qty':3},{'name':'Calamansi Juice','qty':2}],
      subtotal:415, tax:49.8, total:464.8, tableNumber:'T8',
      createdAt: DateTime.now().subtract(const Duration(minutes:2))),
  ];
}