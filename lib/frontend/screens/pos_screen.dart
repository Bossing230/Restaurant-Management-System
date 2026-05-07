import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/pos_bloc.dart';

//final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  // Static menu items — in production these come from MenuBloc
  static const _menu = [
    (1,  'Beef Sinigang',   185.0, 'Main Course'),
    (2,  'Chicken Adobo',   165.0, 'Main Course'),
    (3,  'Pork Sisig',      175.0, 'Main Course'),
    (4,  'Kare-Kare',       220.0, 'Main Course'),
    (5,  'Pancit Canton',   145.0, 'Noodles'),
    (6,  'Palabok',         155.0, 'Noodles'),
    (7,  'Halo-Halo',        95.0, 'Desserts'),
    (8,  'Leche Flan',       75.0, 'Desserts'),
    (9,  'Buko Pandan',      85.0, 'Desserts'),
    (10, 'Sago Gulaman',     55.0, 'Drinks'),
    (11, 'Calamansi Juice',  65.0, 'Drinks'),
    (12, 'Halo-Halo Shake', 115.0, 'Drinks'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) => curr.lastOrderId != null,
      listener: (ctx, state) {
        if (state.lastOrderId != null) _showSuccess(ctx, state.lastOrderId!);
      },
      child: BlocBuilder<PosBloc, PosState>(
        builder: (ctx, state) {
          final isWide = MediaQuery.of(ctx).size.width > 720;
          if (isWide) {
            return Row(children: [
              Expanded(flex: 3, child: _MenuPanel(menu: _menu)),
              Container(width: 1, color: AppColors.border),
              SizedBox(width: 300, child: _CartPanel(state: state)),
            ]);
          }
          return Column(children: [
            Expanded(child: _MenuPanel(menu: _menu)),
            if (state.cart.isNotEmpty)
              _CartSummaryBar(state: state),
          ]);
        },
      ),
    );
  }

  void _showSuccess(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: AppColors.successBg, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppColors.success, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Order placed!', style: AppText.h4),
          const SizedBox(height: 6),
          Text('Order $orderId sent to kitchen.',
            textAlign: TextAlign.center, style: AppText.small),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── Menu panel ────────────────────────────────────────────────
class _MenuPanel extends StatefulWidget {
  final List<(int, String, double, String)> menu;
  const _MenuPanel({required this.menu});
  @override State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  String _cat = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PosBloc>().state;
    final cats  = ['All', ...widget.menu.map((m) => m.$4).toSet()];
    final items = _cat == 'All'
        ? widget.menu
        : widget.menu.where((m) => m.$4 == _cat).toList();

    return Column(children: [
      // Table + type selector
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          const Icon(Icons.table_restaurant_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.table.isEmpty ? null : state.table,
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
            final active = state.orderType == t;
            return GestureDetector(
              onTap: () =>
                  context.read<PosBloc>().add(PosSetTypeEvent(t)),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
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
      ),

      // Category tabs
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cats.map((c) {
              final active = c == _cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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
      ),

      // Menu grid
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: items.length,
          itemBuilder: (ctx2, i) {
            final (id, name, price, cat) = items[i];
            return GestureDetector(
              onTap: () => ctx2.read<PosBloc>()
                  .add(PosAddEvent(id, name, price)),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.primary,
                        size: 24,
                      )),
                    ),
                    const SizedBox(height: 8),
                    Text(name, style: AppText.bodyMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(cat, style: AppText.small),
                    const SizedBox(height: 4),
                    Text('₱${price.toStringAsFixed(0)}',
                      style: AppText.h4.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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