import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/orders_bloc.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _filters = [
    'All', 'Pending', 'Preparing', 'Ready', 'Served', 'Completed',
  ];
  static const _statuses = [
    'Pending', 'Preparing', 'Ready', 'Served', 'Completed', 'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (ctx, state) {
        if (state is OrdersLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is OrdersLoaded) {
          return Column(children: [
            // ── Filter bar ─────────────────────────────────
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(children: [
                // Count chips
                Row(children: [
                  for (final f in ['Pending', 'Preparing', 'Ready'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CountChip(
                        label: f,
                        count: state.all.where((o) => o.status == f).length,
                        color: switch (f) {
                          'Pending'   => AppColors.warning,
                          'Preparing' => AppColors.info,
                          _           => AppColors.success,
                        },
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18,
                        color: AppColors.textSecondary),
                    onPressed: () =>
                        ctx.read<OrdersBloc>().add(OrdersRefreshEvent()),
                  ),
                ]),
                const SizedBox(height: 10),

                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final active = f == state.activeFilter;
                      final count  = f == 'All'
                          ? state.all.length
                          : state.all.where((o) => o.status == f).length;
                      return GestureDetector(
                        onTap: () => ctx.read<OrdersBloc>()
                            .add(OrdersSetFilterEvent(f)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary : AppColors.bgInput,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(children: [
                            Text(f, style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white : AppColors.textSecondary,
                            )),
                            if (count > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white.withOpacity(0.3)
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$count', style: TextStyle(
                                  fontSize: 10,
                                  color: active
                                      ? Colors.white : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                )),
                              ),
                            ],
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),

            // ── Orders grid ────────────────────────────────
            Expanded(
              child: state.filtered.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders found',
                    subtitle: 'Orders will appear here once placed',
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        ctx.read<OrdersBloc>().add(OrdersRefreshEvent()),
                    child: LayoutBuilder(builder: (_, c) {
                      final cols = c.maxWidth > 900 ? 3
                          : c.maxWidth > 600 ? 2 : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: cols == 1 ? 2.2 : 1.5,
                        ),
                        itemCount: state.filtered.length,
                        itemBuilder: (_, i) => _OrderCard(
                          order: state.filtered[i],
                          statuses: _statuses,
                          onStatusChange: (s) => ctx.read<OrdersBloc>()
                              .add(OrdersUpdateStatusEvent(
                                  state.filtered[i].id, s)),
                        ),
                      );
                    }),
                  ),
            ),
          ]);
        }
        return const SizedBox();
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({
    required this.label, required this.count, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text('$count $label', style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final List<String> statuses;
  final void Function(String) onStatusChange;
  const _OrderCard({
    required this.order, required this.statuses, required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: order.isUrgent
                  ? AppColors.dangerBg : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(
              order.tableNumber ?? 'TO',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: order.isUrgent
                    ? AppColors.danger : AppColors.primaryDark),
            )),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.id}', style: AppText.bodyMedium),
              Text('${order.type} · ${order.paymentMethod}',
                  style: AppText.small),
            ],
          )),
          StatusBadge(status: order.status),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Items
        Expanded(
          child: Text(
            order.items.map((i) => '${i['qty']}× ${i['name']}').join(', '),
            style: AppText.small.copyWith(height: 1.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),

        // Footer
        const SizedBox(height: 8),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_cur.format(order.total), style: AppText.h4),
            Text('${order.minutesAgo}m ago',
              style: TextStyle(
                fontSize: 10,
                color: order.isUrgent
                    ? AppColors.danger : AppColors.textSecondary,
              )),
          ]),
          const Spacer(),
          // Status dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: order.status,
                isDense: true,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 14, color: AppColors.textSecondary),
                items: statuses.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s)),
                ).toList(),
                onChanged: (v) { if (v != null) onStatusChange(v); },
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}