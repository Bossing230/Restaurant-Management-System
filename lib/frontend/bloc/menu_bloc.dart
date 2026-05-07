import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';

class MenuItemModel extends Equatable {
  final int id, categoryId;
  final String name, category;
  final double price;
  final String? description, imageUrl;
  final bool available;

  const MenuItemModel({
    required this.id, required this.name, required this.category,
    required this.categoryId, required this.price,
    this.description, this.imageUrl, this.available = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id:          j['id'] as int,
    name:        j['name'] as String,
    category:    j['category'] as String? ?? '',
    categoryId:  j['category_id'] as int? ?? 0,
    price:       double.parse(j['price'].toString()),
    description: j['description'] as String?,
    imageUrl:    j['image_url'] as String?,
    available:   j['available'] as bool? ?? true,
  );

  MenuItemModel copyWith({bool? available}) => MenuItemModel(
    id: id, name: name, category: category, categoryId: categoryId,
    price: price, description: description, imageUrl: imageUrl,
    available: available ?? this.available,
  );

  @override List<Object?> get props => [id, available];
}

// Events
abstract class MenuEvent extends Equatable { @override List<Object?> get props => []; }
class MenuLoadEvent    extends MenuEvent {}
class MenuRefreshEvent extends MenuEvent {}
class MenuSearchEvent  extends MenuEvent {
  final String query;
  MenuSearchEvent(this.query);
  @override List<Object?> get props => [query];
}
class MenuFilterEvent  extends MenuEvent {
  final String category;
  MenuFilterEvent(this.category);
  @override List<Object?> get props => [category];
}
class MenuToggleAvailEvent extends MenuEvent {
  final int id;
  MenuToggleAvailEvent(this.id);
  @override List<Object?> get props => [id];
}

// States
abstract class MenuState extends Equatable { @override List<Object?> get props => []; }
class MenuLoading extends MenuState {}
class MenuLoaded extends MenuState {
  final List<MenuItemModel> all, filtered;
  final String selectedCategory, query;

  MenuLoaded({
    required this.all, required this.filtered,
    this.selectedCategory = 'All', this.query = '',
  });

  List<String> get categories =>
      ['All', ...all.map((m) => m.category).toSet().toList()];

  MenuLoaded copyWith({
    List<MenuItemModel>? all, List<MenuItemModel>? filtered,
    String? selectedCategory, String? query,
  }) => MenuLoaded(
    all:              all              ?? this.all,
    filtered:         filtered         ?? this.filtered,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    query:            query            ?? this.query,
  );

  @override List<Object?> get props => [all, filtered, selectedCategory, query];
}
class MenuError extends MenuState {
  final String message;
  MenuError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final ApiClient _api;
  List<MenuItemModel> _all = [];

  MenuBloc({required ApiClient apiClient})
      : _api = apiClient, super(MenuLoading()) {
    on<MenuLoadEvent>(_onLoad);
    on<MenuRefreshEvent>((_, emit) => _onLoad(MenuLoadEvent(), emit));
    on<MenuSearchEvent>(_onSearch);
    on<MenuFilterEvent>(_onFilter);
    on<MenuToggleAvailEvent>(_onToggle);
  }

  Future<void> _onLoad(MenuLoadEvent _, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      await _api.dio.get(ApiConstants.menu);
      //_all = (res.data['data'] as List).map(MenuItemModel.fromJson).toList();
      emit(MenuLoaded(all: _all, filtered: _all));
    } catch (_) {
      _all = _mockMenu;
      emit(MenuLoaded(all: _all, filtered: _all));
    }
  }

  void _onSearch(MenuSearchEvent e, Emitter<MenuState> emit) {
    if (state is! MenuLoaded) return;
    final s = state as MenuLoaded;
    final q = e.query.toLowerCase().trim();
    emit(s.copyWith(
      query: e.query,
      filtered: _all.where((m) =>
        (s.selectedCategory == 'All' || m.category == s.selectedCategory) &&
        (q.isEmpty || m.name.toLowerCase().contains(q))
      ).toList(),
    ));
  }

  void _onFilter(MenuFilterEvent e, Emitter<MenuState> emit) {
    if (state is! MenuLoaded) return;
    final s = state as MenuLoaded;
    emit(s.copyWith(
      selectedCategory: e.category,
      filtered: _all.where((m) =>
        (e.category == 'All' || m.category == e.category) &&
        (s.query.isEmpty || m.name.toLowerCase().contains(s.query.toLowerCase()))
      ).toList(),
    ));
  }

  void _onToggle(MenuToggleAvailEvent e, Emitter<MenuState> emit) {
    if (state is! MenuLoaded) return;
    _all = _all.map((m) =>
      m.id == e.id ? m.copyWith(available: !m.available) : m
    ).toList();
    add(MenuFilterEvent((state as MenuLoaded).selectedCategory));
    try {
      final item = _all.firstWhere((m) => m.id == e.id);
      _api.dio.put('${ApiConstants.menu}/${e.id}', data: {'available': item.available});
    } catch (_) {}
  }

  static final _mockMenu = [
    const MenuItemModel(id:1,  name:'Beef Sinigang',    category:'Main Course', categoryId:1, price:185, description:'Sour tamarind soup with beef'),
    const MenuItemModel(id:2,  name:'Chicken Adobo',    category:'Main Course', categoryId:1, price:165, description:'Classic braised chicken'),
    const MenuItemModel(id:3,  name:'Pork Sisig',       category:'Main Course', categoryId:1, price:175, description:'Sizzling chopped pork'),
    const MenuItemModel(id:4,  name:'Kare-Kare',        category:'Main Course', categoryId:1, price:220, description:'Oxtail in peanut sauce'),
    const MenuItemModel(id:5,  name:'Pancit Canton',    category:'Noodles',     categoryId:2, price:145),
    const MenuItemModel(id:6,  name:'Palabok',          category:'Noodles',     categoryId:2, price:155),
    const MenuItemModel(id:7,  name:'Halo-Halo',        category:'Desserts',    categoryId:3, price:95),
    const MenuItemModel(id:8,  name:'Leche Flan',       category:'Desserts',    categoryId:3, price:75),
    const MenuItemModel(id:9,  name:'Buko Pandan',      category:'Desserts',    categoryId:3, price:85),
    const MenuItemModel(id:10, name:'Sago Gulaman',     category:'Drinks',      categoryId:4, price:55),
    const MenuItemModel(id:11, name:'Calamansi Juice',  category:'Drinks',      categoryId:4, price:65),
    const MenuItemModel(id:12, name:'Halo-Halo Shake',  category:'Drinks',      categoryId:4, price:115),
    const MenuItemModel(id:13, name:'Lumpiang Shanghai',category:'Appetizers',  categoryId:5, price:120, available:false),
  ];
}