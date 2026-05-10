import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/pos_bloc.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure BLoCs are available
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<MenuBloc>()),
        BlocProvider.value(value: context.read<PosBloc>()),
      ],
      child: const PosScreenContent(),
    );
  }
}

class PosScreenContent extends StatelessWidget {
  const PosScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) => curr.lastOrderId != null && prev.lastOrderId != curr.lastOrderId,
      listener: (ctx, state) {
        if (state.lastOrderId != null) {
          _showSuccess(ctx, state.lastOrderId!);
        }
      },
      child: BlocBuilder<PosBloc, PosState>(
        builder: (ctx, state) {
          final isWide = MediaQuery.of(ctx).size.width > 720;
          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: const _MenuPanel()),
                Container(width: 1, color: AppColors.border),
                SizedBox(width: 300, child: _CartPanel(state: state)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: const _MenuPanel()),
              if (state.cart.isNotEmpty) _CartSummaryBar(state: state),
            ],
          );
        },
      ),
    );
  }

  void _showSuccess(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              width: 56, 
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.successBg, 
                shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Order placed!', style: AppText.h4),
            const SizedBox(height: 6),
            Text('Order $orderId sent to kitchen.',
              textAlign: TextAlign.center, 
              style: AppText.small),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Menu panel ────────────────────────────────────────────────
class _MenuPanel extends StatelessWidget {
  const _MenuPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, menuState) {
        // Handle different states properly
        if (menuState is MenuLoading) {
          // Show empty content while loading (no loading spinner)
          return const _MenuPanelContent(menuState: null);
        }
        
        if (menuState is MenuError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Error: ${menuState.message}', style: AppText.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<MenuBloc>().add(MenuLoadEvent()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (menuState is MenuLoaded) {
          return _MenuPanelContent(menuState: menuState);
        }
        
        // Default - show empty panel
        return const _MenuPanelContent(menuState: null);
      },
    );
  }
}

class _MenuPanelContent extends StatefulWidget {
  final MenuLoaded? menuState;
  const _MenuPanelContent({this.menuState});

  @override
  State<_MenuPanelContent> createState() => _MenuPanelContentState();
}

class _MenuPanelContentState extends State<_MenuPanelContent> {
  String _cat = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final posState = context.watch<PosBloc>().state;
    
    // Get categories and items from menuState (handle null)
    final categories = widget.menuState?.categories ?? ['All', 'Main Course', 'Noodles', 'Desserts', 'Drinks'];
    
    final items = widget.menuState?.filtered.where((item) {
      if (_cat != 'All' && item.category != _cat) return false;
      if (_searchQuery.isNotEmpty && 
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;  
    }).toList() ?? [];

    // If no items, show empty state with header
    if (items.isEmpty) {
      return Column(
        children: [
          _buildHeader(posState),
          _buildSearchBar(),
          if (categories.isNotEmpty && categories.first != 'All') _buildCategoryTabs(categories),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 48, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No menu items found', style: AppText.bodyMedium),
                  SizedBox(height: 8),
                  Text('Try a different category', style: AppText.small),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(posState),
        _buildSearchBar(),
        if (categories.isNotEmpty && categories.length > 1) _buildCategoryTabs(categories),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (ctx2, i) {
              final item = items[i];
              return GestureDetector(
                onTap: item.available
                    ? () => ctx2.read<PosBloc>().add(PosAddEvent(item.id, item.name, item.price))
                    : null,
                child: AppCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            ? Image.asset(
                                item.imageUrl!,
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    _buildImagePlaceholder(),
                              )
                            : _buildImagePlaceholder(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: AppText.small.copyWith(
                          fontWeight: FontWeight.w500,
                          color: item.available ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.category,
                        style: AppText.small.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₱${item.price.toStringAsFixed(0)}',
                            style: AppText.bodyMedium.copyWith(
                              color: item.available ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!item.available)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sold out',
                                style: TextStyle(fontSize: 8, color: AppColors.danger),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(PosState posState) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        const Icon(Icons.table_restaurant_outlined,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: posState.table.isEmpty ? null : posState.table,
            hint: const Text('Table', style: TextStyle(fontSize: 13)),
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 14),
            items: List.generate(10, (i) => 'T${i + 1}')
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                context.read<PosBloc>().add(PosSetTableEvent(v));
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        ...['Dine-in', 'Takeout', 'Delivery'].map((t) {
          final active = posState.orderType == t;
          return GestureDetector(
            onTap: () => context.read<PosBloc>().add(PosSetTypeEvent(t)),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(t, style: TextStyle(
                fontSize: 11,
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search menu...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    // Filter out empty categories
    final validCategories = categories.where((c) => c.isNotEmpty).toList();
    if (validCategories.isEmpty || validCategories.length <= 1) return const SizedBox.shrink();
    
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: validCategories.map((c) {
            final active = c == _cat;
            return GestureDetector(
              onTap: () => setState(() => _cat = c),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.bgInput,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(c, style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : AppColors.textSecondary,
                )),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_outlined,
          color: AppColors.primary,
          size: 30,
        ),
      ),
    );
  }
}

// ── Cart panel (desktop) ──────────────────────────────────────
class _CartPanel extends StatelessWidget {
  final PosState state;
  const _CartPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('Current order', style: AppText.h4),
            const Spacer(),
            if (state.cart.isNotEmpty)
              TextButton(
                onPressed: () =>
                    context.read<PosBloc>().add(PosClearEvent()),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Clear',
                    style: TextStyle(fontSize: 12)),
              ),
          ]),
        ),
        const Divider(height: 1),

        // Items
        Expanded(
          child: state.cart.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 40, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('Tap items to add', style: AppText.small),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.cart.length,
                itemBuilder: (_, i) => _CartItemRow(item: state.cart[i]),
              ),
        ),

        // Footer
        if (state.cart.isNotEmpty) ...[
          const Divider(height: 1),
          _CartFooter(state: state),
        ],
      ]),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(children: [
        _QtyBtn(
          icon: Icons.remove,
          onTap: () => context.read<PosBloc>()
              .add(PosQtyEvent(item.id, item.qty - 1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('${item.qty}', style: AppText.bodyMedium),
        ),
        _QtyBtn(
          icon: Icons.add,
          onTap: () => context.read<PosBloc>()
              .add(PosQtyEvent(item.id, item.qty + 1)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(item.name,
            style: AppText.small.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis)),
        Text('₱${item.subtotal.toStringAsFixed(0)}',
            style: AppText.bodyMedium),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14),
    ),
  );
}

class _CartFooter extends StatelessWidget {
  final PosState state;
  const _CartFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal', style: AppText.small),
          Text('₱${state.subtotal.toStringAsFixed(2)}', style: AppText.small),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tax (12%)', style: AppText.small),
          Text('₱${state.tax.toStringAsFixed(2)}', style: AppText.small),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.border),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: AppText.h4),
          Text('₱${state.total.toStringAsFixed(2)}',
              style: AppText.h4.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),

        // Payment method
        Row(children: [
          Expanded(child: _DropdownField(
            value: state.paymentMethod,
            items: const ['Cash', 'Card', 'E-wallet'],
            icon: Icons.payments_outlined,
            onChanged: (v) =>
                context.read<PosBloc>().add(PosSetPaymentEvent(v)),
          )),
        ]),
        const SizedBox(height: 10),

        // Place order button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.placing || state.cart.isEmpty
                ? null
                : () => context.read<PosBloc>().add(PosPlaceEvent()),
            child: state.placing
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
              : const Text('Place order'),
          ),
        ),
      ]),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final void Function(String) onChanged;
  const _DropdownField({
    required this.value, required this.items,
    required this.icon, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.bgInput,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: false,
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        style: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter'),
        items: items.map((i) => DropdownMenuItem(
          value: i,
          child: Row(children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(i),
          ]),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ),
  );
}

// ── Cart summary bar (mobile) ─────────────────────────────────
class _CartSummaryBar extends StatelessWidget {
  final PosState state;
  const _CartSummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary,
      child: SafeArea(
        top: false,
        child: Row(children: [
          Text('${state.itemCount} items',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('₱${state.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: state.placing
                ? null
                : () => context.read<PosBloc>().add(PosPlaceEvent()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Order', style: TextStyle(fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}