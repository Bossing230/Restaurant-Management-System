import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/menu_bloc.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (ctx, state) {
        if (state is MenuLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is MenuLoaded) return _MenuBody(state: state);
        return const SizedBox();
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
      // ── Search + add button ───────────────────────────
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

      // ── Category tabs ─────────────────────────────────
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

      // ── Items grid ────────────────────────────────────
      Expanded(
        child: state.filtered.isEmpty
          ? EmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'No items found',
              subtitle: 'Try adjusting your search or filter',
              action: AppButton(
                label: 'Clear search',
                outlined: true,
                onPressed: () =>
                    context.read<MenuBloc>().add(MenuSearchEvent('')),
              ),
            )
          : GridView.builder(
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
    showDialog(
      context: context,
      builder: (_) => const _AddMenuItemDialog(),
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
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: item.available
                  ? AppColors.primaryLight : AppColors.bgInput,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md - 1)),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_outlined,
                size: 36,
                color: item.available
                    ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(
                      item.name,
                      style: AppText.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    Switch.adaptive(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => context.read<MenuBloc>()
                          .add(MenuToggleAvailEvent(item.id)),
                    ),
                  ],
                ),
                // Category badge
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
                if (!item.available)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Unavailable',
                      style: TextStyle(
                        fontSize: 10, color: AppColors.danger,
                        fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMenuItemDialog extends StatelessWidget {
  const _AddMenuItemDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add menu item', style: AppText.h4),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.restaurant_menu_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Price (₱)',
                prefixIcon: Icon(Icons.payments_outlined, size: 18),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Add item'),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}