import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuState = context.read<MenuBloc>().state;
      if (menuState is! MenuLoaded) {
        context.read<MenuBloc>().add(MenuLoadEvent());
      }
    });

    return BlocBuilder<MenuBloc, MenuState>(
      builder: (ctx, state) {
        print('DEBUG UI: BlocBuilder rebuilding, state=${state.runtimeType}');
        if (state is MenuLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is MenuLoaded) {
          if (state.filtered.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No menu items', style: AppText.h4),
                  SizedBox(height: 8),
                  Text('Click + to add items', style: AppText.small),
                ],
              ),
            );
          }
          return _MenuBody(state: state);
        }
        if (state is MenuError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Error: ${state.message}', style: AppText.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<MenuBloc>().add(MenuLoadEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _MenuBody extends StatelessWidget {
  final MenuLoaded state;
  const _MenuBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search + add button
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: AppSearchBar(
              hint: 'Search menu items...',
              onChanged: (q) =>
                  context.read<MenuBloc>().add(MenuSearchEvent(q)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
            onPressed: () => _showAddDialog(context),
          ),
        ]),
      ),

      // Category tabs
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: state.categories.map((cat) {
              final active = cat == state.selectedCategory;
              return GestureDetector(
                onTap: () =>
                    context.read<MenuBloc>().add(MenuFilterEvent(cat)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary : AppColors.bgInput,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active
                          ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(cat, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: active
                        ? Colors.white : AppColors.textSecondary,
                  )),
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // Items grid
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: state.filtered.length,
          itemBuilder: (_, i) => _MenuCard(item: state.filtered[i]),
        ),
      ),
    ]);
  }

  void _showAddDialog(BuildContext context) {
    final currentState = context.read<MenuBloc>().state;
    if (currentState is! MenuLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu is still loading...')),
      );
      return;
    }
    
    final categories = currentState.categories
        .where((c) => c != 'All')
        .toList();
    showDialog(
      context: context,
      builder: (_) => _AddMenuItemDialog(categories: categories),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md - 1)),
            child: _buildImage(),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppText.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch.adaptive(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => context.read<MenuBloc>()
                          .add(MenuToggleAvailEvent(item.id)),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    )),
                ),
                if (item.description != null)
                  Text(item.description!,
                    style: AppText.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(
                  '₱${item.price.toStringAsFixed(0)}',
                  style: AppText.h4.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return Container(
        height: 100,
        color: AppColors.primaryLight,
        child: const Icon(Icons.restaurant_outlined, size: 36),
      );
    }

    if (kIsWeb) {
      return Image.network(
        item.imageUrl!,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: AppColors.primaryLight,
          child: const Icon(Icons.restaurant_outlined, size: 36),
        ),
      );
    } else {
      return Image.asset(
        item.imageUrl!,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: AppColors.primaryLight,
          child: const Icon(Icons.restaurant_outlined, size: 36),
        ),
      );
    }
  }
}

class _AddMenuItemDialog extends StatefulWidget {
  final List<String> categories;
  const _AddMenuItemDialog({required this.categories});

  @override
  State<_AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<_AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : 'Main Course';
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    
    setState(() => _isPickingImage = true);
    
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = base64Encode(bytes);
          setState(() {
            _imageUrl = 'data:image/jpeg;base64,$base64String';
          });
        } else {
          setState(() {
            _imageUrl = pickedFile.path;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selected!'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add menu item', style: AppText.h4),
                const SizedBox(height: 20),
                
                GestureDetector(
                  onTap: _isPickingImage ? null : _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isPickingImage
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(height: 8),
                                Text('Opening gallery...', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          )
                        : _imageUrl != null
                            ? kIsWeb
                                ? Image.network(
                                    _imageUrl!,
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                  )
                                : Image.file(
                                    File(_imageUrl!),
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                  )
                            : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined, size: 18),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₱)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Enter price';
                    if (double.tryParse(v!) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                  ),
                  items: widget.categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined, size: 18),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _addMenuItem(context),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add item'),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 32, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          'Tap to select image',
          style: AppText.small.copyWith(
            color: AppColors.textSecondary),
        ),
      ],
    );
  }

     Future<void> _addMenuItem(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentState = context.read<MenuBloc>().state;
      print('DEBUG: Current state type before cast: ${currentState.runtimeType}');
      
      if (currentState is! MenuLoaded) {
        print('DEBUG ERROR: State is not MenuLoaded, aborting');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait, menu is loading...')),
          );
        }
        return;
      }
      
      final menuState = currentState;
      
      final categoryMap = <String, int>{};
      for (final item in menuState.all) {
        if (!categoryMap.containsKey(item.category)) {
          categoryMap[item.category] = item.categoryId;
        }
      }
      
      print('DEBUG: Available categories: $categoryMap');
      print('DEBUG: Selected category: $_selectedCategory');
      
      final nextId = menuState.all.isEmpty 
          ? 1 
          : menuState.all.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
      
      final newItem = MenuItemModel(
        id: nextId,
        name: _nameController.text,
        category: _selectedCategory!,
        categoryId: categoryMap[_selectedCategory!] ?? 1,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        imageUrl: _imageUrl,
        available: true,
      );

      print('DEBUG: New item: id=${newItem.id}, name=${newItem.name}, category=${newItem.category}');
      
      context.read<MenuBloc>().add(MenuAddItemEvent(newItem));
      print('DEBUG: MenuAddItemEvent dispatched');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}