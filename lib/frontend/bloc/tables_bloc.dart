import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

class TableModel extends Equatable {
  final int id, capacity;
  final String number, status;
  final String? currentOrderId, waiterName, section;

  const TableModel({
    required this.id, required this.number,
    required this.capacity, required this.status,
    this.currentOrderId, this.waiterName, this.section,
  });

  factory TableModel.fromJson(Map<String, dynamic> j) => TableModel(
    id:             j['id'] as int,
    number:         j['number'] as String,
    capacity:       j['capacity'] as int? ?? 4,
    status:         j['status'] as String,
    currentOrderId: j['current_order_id']?.toString(),
    waiterName:     j['waiter_name'] as String?,
    section:        j['section'] as String?,
  );

  TableModel copyWith({String? status}) => TableModel(
    id: id, number: number, capacity: capacity,
    status: status ?? this.status,
    currentOrderId: currentOrderId,
    waiterName: waiterName, section: section,
  );

  @override List<Object?> get props => [id, status];
}

// Events
abstract class TablesEvent extends Equatable { @override List<Object?> get props => []; }
class TablesLoadEvent extends TablesEvent {}
class TablesRefreshEvent extends TablesEvent {}
class TableUpdateStatusEvent extends TablesEvent {
  final int id; final String status;
  TableUpdateStatusEvent(this.id, this.status);
  @override List<Object?> get props => [id, status];
}

// States
abstract class TablesState extends Equatable { @override List<Object?> get props => []; }
class TablesLoading extends TablesState {}
class TablesLoaded extends TablesState {
  final List<TableModel> tables;
  TablesLoaded(this.tables);
  int get available => tables.where((t) => t.status == 'available').length;
  int get occupied  => tables.where((t) => t.status == 'occupied').length;
  int get reserved  => tables.where((t) => t.status == 'reserved').length;
  @override List<Object?> get props => [tables];
}
class TablesError extends TablesState {
  final String message;
  TablesError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class TablesBloc extends Bloc<TablesEvent, TablesState> {
  final ApiClient _api;

  TablesBloc({required ApiClient apiClient})
      : _api = apiClient, super(TablesLoading()) {
    on<TablesLoadEvent>(_onLoad);
    on<TablesRefreshEvent>((_, emit) => _onLoad(TablesLoadEvent(), emit));
    on<TableUpdateStatusEvent>(_onUpdate);
  }

  Future<void> _onLoad(TablesLoadEvent _, Emitter<TablesState> emit) async {
    emit(TablesLoading());
    try {
      final res = await _api.dio.get(ApiConstants.tables);
      emit(TablesLoaded(
        (res.data['data'] as List<dynamic>).map((e) => TableModel.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    } catch (_) {
      emit(TablesLoaded(_mockTables));
    }
  }

  Future<void> _onUpdate(TableUpdateStatusEvent e, Emitter<TablesState> emit) async {
    if (state is! TablesLoaded) return;
    final s = state as TablesLoaded;
    emit(TablesLoaded(
      s.tables.map((t) => t.id == e.id ? t.copyWith(status: e.status) : t).toList(),
    ));
    try {
      await _api.dio.put('${ApiConstants.tables}/${e.id}/status', data: {'status': e.status});
    } catch (_) {}
  }

  static final _mockTables = [
    const TableModel(id:1,  number:'T1',  capacity:4, status:'occupied',  waiterName:'Jose',  section:'indoor'),
    const TableModel(id:2,  number:'T2',  capacity:4, status:'available',                     section:'indoor'),
    const TableModel(id:3,  number:'T3',  capacity:6, status:'occupied',  waiterName:'Maria', section:'indoor'),
    const TableModel(id:4,  number:'T4',  capacity:2, status:'reserved',                      section:'indoor'),
    const TableModel(id:5,  number:'T5',  capacity:4, status:'available',                     section:'indoor'),
    const TableModel(id:6,  number:'T6',  capacity:6, status:'occupied',  waiterName:'Ana',   section:'outdoor'),
    const TableModel(id:7,  number:'T7',  capacity:4, status:'available',                     section:'outdoor'),
    const TableModel(id:8,  number:'T8',  capacity:8, status:'reserved',                      section:'private'),
    const TableModel(id:9,  number:'T9',  capacity:2, status:'available',                     section:'indoor'),
    const TableModel(id:10, number:'T10', capacity:4, status:'occupied',  waiterName:'Pedro', section:'outdoor'),
  ];
}