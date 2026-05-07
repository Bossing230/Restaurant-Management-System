import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/bloc/dashboard_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

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
            child: _ManagerBody(state: state),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _ManagerBody extends StatelessWidget {
  final DashboardLoaded state;
  const _ManagerBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Metrics
              LayoutBuilder(builder: (_, c) {
                final cols = c.maxWidth > 600 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cols, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65,
                  children: [
                    MetricCard(label: "Today's sales",    value: _cur.format(state.summary.totalSales),    change: '+${state.summary.salesChangePercent.toStringAsFixed(0)}%', positive: true, icon: Icons.payments_outlined,         iconColor: AppColors.primary, iconBg: AppColors.primaryLight),
                    MetricCard(label: 'Total orders',     value: '${state.summary.totalOrders}',           icon: Icons.receipt_long_outlined,    iconColor: AppColors.info,    iconBg: AppColors.infoBg),
                    MetricCard(label: 'Staff on duty',    value: '${state.staff.where((s) => s.status == "online").length}/${state.staff.length}', icon: Icons.people_outline, iconColor: AppColors.success, iconBg: AppColors.successBg),
                    MetricCard(label: 'Low stock alerts', value: '${state.summary.lowStockItems}',         icon: Icons.inventory_2_outlined,     iconColor: AppColors.danger,  iconBg: AppColors.dangerBg),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Sales trend line chart
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionHeader(title: 'Sales trend', subtitle: 'Last 7 days'),
                  const SizedBox(height: 16),
                  SizedBox(height: 180, child: _SalesTrendChart(data: state.salesData)),
                ]),
              ),
              const SizedBox(height: 12),

              // Two columns
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 680) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _TopItemsCard(items: state.topItems)),
                    const SizedBox(width: 12),
                    Expanded(child: _AlertsCard(alerts: state.alerts)),
                  ]);
                }
                return Column(children: [
                  _TopItemsCard(items: state.topItems),
                  const SizedBox(height: 12),
                  _AlertsCard(alerts: state.alerts),
                ]);
              }),
              const SizedBox(height: 12),

              // Staff activity
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionHeader(title: 'Staff activity'),
                  const SizedBox(height: 12),
                  ...state.staff.map((s) {
                    final dotColor = s.status == 'online' ? AppColors.success
                        : s.status == 'break' ? AppColors.warning : AppColors.textHint;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        UserAvatar(name: s.name, size: 34),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name, style: AppText.bodyMedium),
                          Text(s.role, style: AppText.small),
                        ])),
                        if (s.salesAmount > 0)
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_cur.format(s.salesAmount), style: AppText.bodyMedium),
                            Text('${s.ordersHandled} orders', style: AppText.small),
                          ]),
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
}

class _SalesTrendChart extends StatelessWidget {
  final List<SalesPoint> data;
  const _SalesTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty ? 20000.0
        : data.map((d) => d.amount).reduce((a, b) => a > b ? a : b) * 1.25;

    return LineChart(LineChartData(
      maxY: maxY, minY: 0,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          //tooltipBgColor: AppColors.textPrimary,
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            '₱${(s.y / 1000).toStringAsFixed(1)}k',
            const TextStyle(color: Colors.white, fontSize: 11),
          )).toList(),
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(v.toInt() < data.length ? data[v.toInt()].label : '',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
        isCurved: true, color: AppColors.primary, barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
      )],
    ));
  }
}

class _TopItemsCard extends StatelessWidget {
  final List<TopItem> items;
  const _TopItemsCard({required this.items});
  static const _colors = [AppColors.primary, AppColors.info, AppColors.success, AppColors.warning, AppColors.danger];

  @override
  Widget build(BuildContext context) {
    final max = items.isEmpty ? 1 : items.first.quantitySold;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Top selling items'),
        const SizedBox(height: 12),
        ...items.take(5).toList().asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(children: [
              Row(children: [
                Container(width: 20, height: 20,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.name, style: AppText.bodyMedium, overflow: TextOverflow.ellipsis)),
                Text('${e.value.quantitySold} sold', style: AppText.small),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: e.value.quantitySold / max, minHeight: 4,
                  backgroundColor: color.withOpacity(0.1), color: color)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<DashboardAlert> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Alerts'),
        const SizedBox(height: 10),
        if (alerts.isEmpty)
          const Text('All systems OK', style: AppText.small)
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
                Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
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