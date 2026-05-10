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
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.price,
    this.description,
    this.imageUrl,
    this.available = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id: j['id'] as int,
    name: j['name'] as String,
    category: j['category'] as String? ?? '',
    categoryId: j['category_id'] as int? ?? 0,
    price: double.parse(j['price'].toString()),
    description: j['description'] as String?,
    imageUrl: j['image_url'] as String?,
    available: j['available'] as bool? ?? true,
  );

  MenuItemModel copyWith({bool? available}) => MenuItemModel(
    id: id,
    name: name,
    category: category,
    categoryId: categoryId,
    price: price,
    description: description,
    imageUrl: imageUrl,
    available: available ?? this.available,
  );

  @override
  List<Object?> get props => [id, available];
}

// Events
abstract class MenuEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MenuLoadEvent extends MenuEvent {}
class MenuRefreshEvent extends MenuEvent {}
class MenuSearchEvent extends MenuEvent {
  final String query;
  MenuSearchEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class MenuFilterEvent extends MenuEvent {
  final String category;
  MenuFilterEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class MenuToggleAvailEvent extends MenuEvent {
  final int id;
  MenuToggleAvailEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// ADD THIS EVENT
class MenuAddItemEvent extends MenuEvent {
  final MenuItemModel item;
  MenuAddItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

// States
abstract class MenuState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {}
class MenuLoaded extends MenuState {
  final List<MenuItemModel> all, filtered;
  final String selectedCategory, query;

  MenuLoaded({
    required this.all,
    required this.filtered,
    this.selectedCategory = 'All',
    this.query = '',
  });

  List<String> get categories =>
      ['All', ...all.map((m) => m.category).toSet().toList()];

  MenuLoaded copyWith({
    List<MenuItemModel>? all,
    List<MenuItemModel>? filtered,
    String? selectedCategory,
    String? query,
  }) => MenuLoaded(
    all: all ?? this.all,
    filtered: filtered ?? this.filtered,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [
    all.length,        // Use length instead of the list itself
    filtered.length,
    selectedCategory,
    query,
    all.map((m) => m.id).join(','),  // Include IDs to detect changes
  ];
}

class MenuError extends MenuState {
  final String message;
  MenuError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final ApiClient _api;
  List<MenuItemModel> _all = [];

  MenuBloc({required ApiClient apiClient})
      : _api = apiClient,
        super(MenuLoading()) {
    on<MenuLoadEvent>(_onLoad);
    on<MenuRefreshEvent>((_, emit) => _onLoad(MenuLoadEvent(), emit));
    on<MenuSearchEvent>(_onSearch);
    on<MenuFilterEvent>(_onFilter);
    on<MenuToggleAvailEvent>(_onToggle);
    on<MenuAddItemEvent>(_onAddItem); // Add this line
  }

  Future<void> _onLoad(MenuLoadEvent _, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final res = await _api.dio.get(ApiConstants.menu);
      final List data = res.data['data'] ?? [];
      _all = data.map((j) => MenuItemModel.fromJson(j)).toList();
      emit(MenuLoaded(all: _all, filtered: _all));
    } catch (e) {
      _all = List.from(_mockMenu);
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
    
    final currentState = state as MenuLoaded;
    final newFiltered = _all.where((m) =>
      (currentState.selectedCategory == 'All' || m.category == currentState.selectedCategory) &&
      (currentState.query.isEmpty || m.name.toLowerCase().contains(currentState.query.toLowerCase()))
    ).toList();
    
    emit(currentState.copyWith(all: _all, filtered: newFiltered));
    
    try {
      final item = _all.firstWhere((m) => m.id == e.id);
      _api.dio.put('${ApiConstants.menu}/${e.id}', data: {'available': item.available});
    } catch (_) {}
  }

  // ADD THIS METHOD
   void _onAddItem(MenuAddItemEvent event, Emitter<MenuState> emit) async {
    print('DEBUG BLOC: _onAddItem called for ${event.item.name}');
    print('DEBUG BLOC: Current state type: ${state.runtimeType}');
    
     if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      
      // Create completely new lists
      final newAll = List<MenuItemModel>.from(_all)..add(event.item);
      _all = newAll;
      
      final newFiltered = List<MenuItemModel>.from(newAll.where((m) =>
        (currentState.selectedCategory == 'All' || m.category == currentState.selectedCategory) &&
        (currentState.query.isEmpty || m.name.toLowerCase().contains(currentState.query.toLowerCase()))
      ));
      
      emit(MenuLoaded(
        all: newAll,
        filtered: newFiltered,
        selectedCategory: currentState.selectedCategory,
        query: currentState.query,
      ));
  }
}

  static final List<MenuItemModel> _mockMenu = [
    const MenuItemModel(id: 1, name: 'Beef Sinigang', category: 'Main Course', categoryId: 1, price: 185, description: 'Sour tamarind soup with beef', imageUrl: 'assets/images/beef_sinigang.jpg'),
    const MenuItemModel(id: 2, name: 'Chicken Adobo', category: 'Main Course', categoryId: 1, price: 165, description: 'Classic braised chicken', imageUrl: 'assets/images/chicken_adobo.jpg'),
    const MenuItemModel(id: 3, name: 'Pork Sisig', category: 'Main Course', categoryId: 1, price: 175, description: 'Sizzling chopped pork', imageUrl: 'assets/images/pork_sisig.jpg'),
    const MenuItemModel(id: 4, name: 'Kare-Kare', category: 'Main Course', categoryId: 1, price: 220, description: 'Oxtail in peanut sauce', imageUrl: 'assets/images/kare_kare.jpg'),
    const MenuItemModel(id: 5, name: 'Pancit Canton', category: 'Noodles', categoryId: 2, price: 145, imageUrl: 'assets/images/pancit_canton.jpg'),
    const MenuItemModel(id: 6, name: 'Palabok', category: 'Noodles', categoryId: 2, price: 155, imageUrl: 'assets/images/palabok.jpg'),
    const MenuItemModel(id: 7, name: 'Halo-Halo', category: 'Desserts', categoryId: 3, price: 95, imageUrl: 'assets/images/halo_halo.jpg'),
    const MenuItemModel(id: 8, name: 'Leche Flan', category: 'Desserts', categoryId: 3, price: 75, imageUrl: 'assets/images/leche_flan.jpg'),
    const MenuItemModel(id: 9, name: 'Buko Pandan', category: 'Desserts', categoryId: 3, price: 85, imageUrl: 'assets/images/buko_pandan.jpg'),
    const MenuItemModel(id: 10, name: 'Sago Gulaman', category: 'Drinks', categoryId: 4, price: 55, imageUrl: 'assets/images/sago_gulaman.jpg'),
    const MenuItemModel(id: 11, name: 'Calamansi Juice', category: 'Drinks', categoryId: 4, price: 65, imageUrl: 'assets/images/calamansi_juice.jpg'),
    const MenuItemModel(id: 12, name: 'Halo-Halo Shake', category: 'Drinks', categoryId: 4, price: 115, imageUrl: 'assets/images/halo_halo_shake.jpg'),
    const MenuItemModel(id: 13, name: 'Lumpiang Shanghai', category: 'Appetizers', categoryId: 5, price: 120, available: true),
  ];
}