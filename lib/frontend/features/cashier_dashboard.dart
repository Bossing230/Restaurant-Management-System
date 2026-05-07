import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

class CashierDashboardScreen extends StatelessWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (ctx, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is DashboardLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ctx.read<DashboardBloc>().add(DashboardRefreshEvent()),
            child: _CashierBody(state: state),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _CashierBody extends StatelessWidget {
  final DashboardLoaded state;
  const _CashierBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Metrics grid
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 600 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65,
            children: [
              MetricCard(
                label: 'My sales today',
                value: _cur.format(state.summary.totalSales),
                change: '+${state.summary.totalOrders} orders',
                positive: true,
                icon: Icons.payments_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryLight,
              ),
              MetricCard(
                label: 'Pending orders',
                value: '${state.summary.pendingOrders}',
                icon: Icons.pending_actions_outlined,
                iconColor: AppColors.warning,
                iconBg: AppColors.warningBg,
              ),
              MetricCard(
                label: 'Available tables',
                value: '${state.summary.availableTables}',
                icon: Icons.table_restaurant_outlined,
                iconColor: AppColors.success,
                iconBg: AppColors.successBg,
              ),
              MetricCard(
                label: 'Avg order value',
                value: '₱285',
                icon: Icons.trending_up_outlined,
                iconColor: AppColors.info,
                iconBg: AppColors.infoBg,
              ),
            ],
          );
        }),
        const SizedBox(height: 16),

        // Quick actions
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _QuickAction(
                icon: Icons.add_shopping_cart_outlined,
                label: 'New order',
                color: AppColors.primary,
                onTap: () => context.go('/pos'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'View orders',
                color: AppColors.info,
                onTap: () => context.go('/orders'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(
                icon: Icons.table_restaurant_outlined,
                label: 'Tables',
                color: AppColors.success,
                onTap: () => context.go('/tables'),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Recent orders
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(
              title: 'Recent orders',
              action: TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View all',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 8),
            if (state.recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No orders yet today', style: AppText.small),
                ),
              )
            else
              ...state.recentOrders.take(5).map((o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(
                      o.tableNo,
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${o.id}', style: AppText.bodyMedium),
                      Text('${o.itemCount} items · ${o.type}', style: AppText.small),
                    ],
                  )),
                  StatusBadge(status: o.status),
                  const SizedBox(width: 10),
                  Text(_cur.format(o.total), style: AppText.bodyMedium),
                ]),
              )),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}