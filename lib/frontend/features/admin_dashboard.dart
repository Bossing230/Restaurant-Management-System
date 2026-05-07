import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (ctx, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const _DashSkeleton();
        }
        if (state is DashboardLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ctx.read<DashboardBloc>().add(DashboardRefreshEvent()),
            child: _AdminBody(state: state),
          );
        }
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      },
    );
  }
}

class _AdminBody extends StatelessWidget {
  final DashboardLoaded state;
  const _AdminBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Greeting + date ────────────────────────────
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Good ${_greeting()},', style: AppText.small),
                  const SizedBox(height: 2),
                  Text("Today's overview", style: AppText.h3),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(children: [
                    const LiveDot(),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: AppText.small.copyWith(
                        color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Range selector ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: ['daily', 'weekly', 'monthly'].map((r) {
                  final active = r == state.range;
                  return GestureDetector(
                    onTap: () => context.read<DashboardBloc>()
                        .add(DashboardLoadEvent(range: r)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        r[0].toUpperCase() + r.substring(1),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Metrics grid ───────────────────────────────
              LayoutBuilder(builder: (_, c) {
                final cols = c.maxWidth > 700 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  children: [
                    MetricCard(
                      label: "Today's revenue",
                      value: _cur.format(state.summary.totalSales),
                      change: '+${state.summary.salesChangePercent.toStringAsFixed(0)}%',
                      positive: true,
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                    ),
                    MetricCard(
                      label: 'Active orders',
                      value: '${state.summary.totalOrders}',
                      change: '+${state.summary.pendingOrders} pending',
                      positive: state.summary.pendingOrders < 10,
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.info,
                      iconBg: AppColors.infoBg,
                    ),
                    MetricCard(
                      label: 'Available tables',
                      value: '${state.summary.availableTables}',
                      icon: Icons.table_restaurant_outlined,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successBg,
                    ),
                    MetricCard(
                      label: 'Low stock items',
                      value: '${state.summary.lowStockItems}',
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.danger,
                      iconBg: AppColors.dangerBg,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // ── Charts row ─────────────────────────────────
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 680) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _RevenueChart(data: state.salesData)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _TopItemsCard(items: state.topItems)),
                  ]);
                }
                return Column(children: [
                  _RevenueChart(data: state.salesData),
                  const SizedBox(height: 12),
                  _TopItemsCard(items: state.topItems),
                ]);
              }),
              const SizedBox(height: 12),

              // ── Recent orders + alerts ─────────────────────
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 680) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _RecentOrdersCard(orders: state.recentOrders)),
                    const SizedBox(width: 12),
                    SizedBox(width: 280, child: _AlertsCard(alerts: state.alerts)),
                  ]);
                }
                return Column(children: [
                  _RecentOrdersCard(orders: state.recentOrders),
                  const SizedBox(height: 12),
                  _AlertsCard(alerts: state.alerts),
                ]);
              }),
              const SizedBox(height: 12),

              // ── Staff activity ─────────────────────────────
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionHeader(title: 'Staff on duty', subtitle: 'Today'),
                  const SizedBox(height: 12),
                  ...state.staff.map((s) {
                    final dotColor = s.status == 'online'
                        ? AppColors.success
                        : s.status == 'break'
                            ? AppColors.warning
                            : AppColors.textHint;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        UserAvatar(name: s.name, size: 34),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: AppText.bodyMedium),
                            Text(s.role,  style: AppText.small),
                          ],
                        )),
                        if (s.salesAmount > 0) Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_cur.format(s.salesAmount), style: AppText.bodyMedium),
                            Text('${s.ordersHandled} orders', style: AppText.small),
                          ],
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Revenue bar chart ─────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<SalesPoint> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 20000.0
        : data.map((d) => d.amount).reduce((a, b) => a > b ? a : b) * 1.25;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Revenue overview',
          action: Row(children: [
            const LiveDot(), const SizedBox(width: 6),
            const Text('Live', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                //tooltipBgColor: AppColors.textPrimary,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${data[group.x].label}\n₱${(rod.toY / 1000).toStringAsFixed(1)}k',
                  const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 22,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    v.toInt() < data.length ? data[v.toInt()].label : '',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  '₱${(v / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              )),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.border, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(
                toY:    e.value.amount,
                color:  e.key == 5 ? AppColors.primary : AppColors.primaryLight,
                width:  20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )],
            )).toList(),
          )),
        ),
      ]),
    );
  }
}

// ── Top items card ────────────────────────────────────────────
class _TopItemsCard extends StatelessWidget {
  final List<TopItem> items;
  const _TopItemsCard({required this.items});

  static const _colors = [
    AppColors.primary, AppColors.info, AppColors.success,
    AppColors.warning, AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final max = items.isEmpty ? 1 : items.first.quantitySold;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Top items', subtitle: 'This week'),
        const SizedBox(height: 12),
        ...items.take(5).toList().asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(child: Text(
                    '${e.key + 1}',
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.name, style: AppText.bodyMedium, overflow: TextOverflow.ellipsis)),
                Text('${e.value.quantitySold}', style: AppText.small),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           e.value.quantitySold / max,
                  minHeight:       4,
                  backgroundColor: color.withOpacity(0.1),
                  color:           color,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Recent orders ─────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  final List<RecentOrder> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recent orders'),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No orders yet today', style: AppText.small)),
          )
        else
          ...orders.map((o) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(
                  o.tableNo,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order #${o.id}', style: AppText.bodyMedium),
                Text('${o.itemCount} items · ${o.type}', style: AppText.small),
              ])),
              StatusBadge(status: o.status),
              const SizedBox(width: 10),
              Text(_cur.format(o.total), style: AppText.bodyMedium),
            ]),
          )),
      ]),
    );
  }
}

// ── Alerts ────────────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final List<DashboardAlert> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Alerts',
          action: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${alerts.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (alerts.isEmpty)
          const Text('All clear — no alerts', style: AppText.small)
        else
          ...alerts.map((a) {
            final (bg, dot) = switch (a.level) {
              'high'   => (AppColors.dangerBg,  AppColors.danger),
              'medium' => (AppColors.warningBg, AppColors.warning),
              _        => (AppColors.infoBg,    AppColors.info),
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dot)),
                  const SizedBox(height: 2),
                  Text(a.description, style: AppText.small),
                ])),
              ]),
            );
          }),
      ]),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────
class _DashSkeleton extends StatelessWidget {
  const _DashSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        GridView.count(
          crossAxisCount: 4, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65,
          children: List.generate(4, (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          )),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ]),
    );
  }
}