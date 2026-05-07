import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (ctx, state) {
        if (state is InventoryLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is InventoryLoaded) {
          return _InventoryBody(state: state);
        }
        return const SizedBox();
      },
    );
  }
}

class _InventoryBody extends StatelessWidget {
  final InventoryLoaded state;
  const _InventoryBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ────────────────────────────────────────
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Expanded(
            child: AppSearchBar(hint: 'Search inventory...'),
          ),
          const SizedBox(width: 12),
          if (state.lowItems.isNotEmpty)
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Restock all low'),
              onPressed: () => context.read<InventoryBloc>()
                  .add(InventoryRestockAllEvent()),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
            onPressed: () => _showAddDialog(context),
          ),
        ]),
      ),

      // ── Low stock warning banner ───────────────────────
      if (state.lowItems.isNotEmpty)
        Container(
          width: double.infinity,
          color: AppColors.dangerBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.warning_amber_outlined,
                size: 16, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(
              '${state.lowItems.length} item${state.lowItems.length > 1 ? 's' : ''} '
              'below 30% stock level',
              style: const TextStyle(
                fontSize: 12, color: AppColors.danger,
                fontWeight: FontWeight.w500),
            ),
          ]),
        ),

      // ── Inventory list ────────────────────────────────
      Expanded(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => context.read<InventoryBloc>()
              .add(InventoryRefreshEvent()),
          child: state.items.isEmpty
            ? const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No inventory items',
                subtitle: 'Add items to start tracking stock',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InventoryCard(item: state.items[i]),
              ),
        ),
      ),
    ]);
  }

  void _showAddDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add inventory item', style: AppText.h4),
              const SizedBox(height: 20),
              const TextField(decoration: InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
              )),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'Current stock'),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'Max stock'),
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'Unit (kg, btl...)'),
                )),
                const SizedBox(width: 12),
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'Category'),
                )),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Add item'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    //final pctColor = item.pct < 0.2
    //    ? AppColors.danger
    //    : item.pct < 0.5
    //        ? AppColors.warning
    //        : AppColors.success;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: item.isLow ? AppColors.dangerBg : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: item.isLow ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Name + category
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppText.bodyMedium),
              Text(item.category, style: AppText.small),
            ],
          )),

          // Status badge
          StatusBadge(status: item.isLow ? 'Low stock' : 'In stock'),
          const SizedBox(width: 10),

          // Stock amount
          Text(
            '${item.stock.toStringAsFixed(1)} / '
            '${item.maxStock.toStringAsFixed(0)} ${item.unit}',
            style: AppText.small,
          ),
          const SizedBox(width: 10),

          // Restock button
          if (item.isLow)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.success, size: 20),
              onPressed: () => context.read<InventoryBloc>()
                  .add(InventoryRestockEvent(item.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ]),

        const SizedBox(height: 10),

        // Stock progress bar
        StockBar(
          value: item.pct,
          label: '${(item.pct * 100).toInt()}% remaining',
        ),
      ]),
    );
  }
}