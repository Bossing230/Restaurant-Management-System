import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/orders_bloc.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (ctx, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is OrdersLoaded) {
          final active = state.all
              .where((o) => o.status != 'Completed' && o.status != 'Cancelled')
              .toList();
          return Column(children: [
            // Live header strip
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                const LiveDot(),
                const SizedBox(width: 8),
                const Text('Kitchen Display', style: AppText.bodyMedium),
                const Spacer(),
                _KitchenChip('${active.where((o) => o.status == "Pending").length} new',     AppColors.warningBg, AppColors.warning),
                const SizedBox(width: 8),
                _KitchenChip('${active.where((o) => o.status == "Preparing").length} cooking', AppColors.infoBg,    AppColors.info),
                const SizedBox(width: 8),
                _KitchenChip('${active.where((o) => o.status == "Ready").length} ready',     AppColors.successBg, AppColors.success),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                  onPressed: () => ctx.read<OrdersBloc>().add(OrdersRefreshEvent()),
                ),
              ]),
            ),

            // Kanban columns
            Expanded(
              child: active.isEmpty
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
                      SizedBox(height: 12),
                      Text('All caught up!', style: AppText.h4),
                      SizedBox(height: 4),
                      Text('No active orders', style: AppText.small),
                    ]))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KanbanColumn(
                        title: 'New',
                        color: AppColors.warning,
                        orders: active.where((o) => o.status == 'Pending').toList(),
                        nextStatus: 'Preparing',
                        nextLabel: 'Start cooking',
                      ),
                      _KanbanColumn(
                        title: 'Cooking',
                        color: AppColors.info,
                        orders: active.where((o) => o.status == 'Preparing').toList(),
                        nextStatus: 'Ready',
                        nextLabel: 'Mark ready',
                      ),
                      _KanbanColumn(
                        title: 'Ready',
                        color: AppColors.success,
                        orders: active.where((o) => o.status == 'Ready').toList(),
                        nextStatus: 'Completed',
                        nextLabel: 'Completed',
                      ),
                    ],
                  ),
            ),
          ]);
        }
        return const SizedBox();
      },
    );
  }
}

Widget _KitchenChip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
  child: Text(label, style: TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
);

class _KanbanColumn extends StatelessWidget {
  final String title, nextStatus, nextLabel;
  final Color color;
  final List<OrderModel> orders;
  const _KanbanColumn({
    required this.title, required this.color,
    required this.orders, required this.nextStatus, required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Column header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(children: [
              Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text(title, style: AppText.h4.copyWith(color: color)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('${orders.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
          ),

          // Order cards
          Expanded(
            child: orders.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 28,
                      color: color.withOpacity(0.3)),
                    const SizedBox(height: 6),
                    Text('All clear', style: AppText.small.copyWith(
                      color: color.withOpacity(0.5))),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _KitchenCard(
                    order: orders[i],
                    nextStatus: nextStatus,
                    nextLabel: nextLabel,
                  ),
                ),
          ),
        ]),
      ),
    );
  }
}

class _KitchenCard extends StatefulWidget {
  final OrderModel order;
  final String nextStatus, nextLabel;
  const _KitchenCard({
    required this.order, required this.nextStatus, required this.nextLabel,
  });
  @override State<_KitchenCard> createState() => _KitchenCardState();
}

class _KitchenCardState extends State<_KitchenCard> {
  final Set<int> _checked = {};

  Color get _timerColor {
    final mins = widget.order.minutesAgo;
    if (mins > 20) return AppColors.danger;
    if (mins > 10) return AppColors.warning;
    return AppColors.info;
  }

  Color get _timerBg {
    final mins = widget.order.minutesAgo;
    if (mins > 20) return AppColors.dangerBg;
    if (mins > 10) return AppColors.warningBg;
    return AppColors.infoBg;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: o.isUrgent ? AppColors.danger.withOpacity(0.4) : AppColors.border,
          width: o.isUrgent ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Text('#${o.id}', style: AppText.bodyMedium),
            const SizedBox(width: 6),
            Text(
              '${o.tableNumber ?? 'TO'} · ${o.type}',
              style: AppText.small,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _timerBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('${o.minutesAgo}m',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: _timerColor)),
            ),
          ]),
          const SizedBox(height: 10),

          // Item checklist
          ...o.items.asMap().entries.map((e) {
            final done = _checked.contains(e.key);
            return GestureDetector(
              onTap: () => setState(() =>
                done ? _checked.remove(e.key) : _checked.add(e.key)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: done ? AppColors.success : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: done ? AppColors.success : AppColors.border),
                    ),
                    child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value['qty']}× ${e.value['name']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: done ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 10),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<OrdersBloc>().add(
                OrdersUpdateStatusEvent(o.id, widget.nextStatus),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.nextStatus == 'Ready'
                    ? AppColors.success
                    : widget.nextStatus == 'Completed'
                        ? AppColors.textSecondary
                        : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(widget.nextLabel,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}