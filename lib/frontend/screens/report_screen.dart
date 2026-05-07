import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (ctx, state) {
        if (state is ReportsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is ReportsLoaded) {
          return _ReportsBody(state: state);
        }
        return const SizedBox();
      },
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<ReportsBloc>()
          .add(ReportsLoadEvent(range: state.range)),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Range selector ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: ['daily', 'weekly', 'monthly'].map((r) {
                    final active = r == state.range;
                    return GestureDetector(
                      onTap: () => context.read<ReportsBloc>()
                          .add(ReportsLoadEvent(range: r)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary : AppColors.bgInput,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          r[0].toUpperCase() + r.substring(1),
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: active
                                ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Summary metrics ────────────────────
                LayoutBuilder(builder: (_, c) {
                  final cols = c.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      MetricCard(
                        label: 'Total revenue',
                        value: _cur.format(state.totalRevenue),
                        change: '+18%',
                        positive: true,
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.primaryLight,
                      ),
                      MetricCard(
                        label: 'Total orders',
                        value: '${state.totalOrders}',
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.info,
                        iconBg: AppColors.infoBg,
                      ),
                      MetricCard(
                        label: 'Avg. order value',
                        value: _cur.format(state.avgOrderValue),
                        icon: Icons.show_chart_outlined,
                        iconColor: AppColors.success,
                        iconBg: AppColors.successBg,
                      ),
                      MetricCard(
                        label: 'Best day',
                        value: 'Saturday',
                        icon: Icons.star_outline,
                        iconColor: AppColors.warning,
                        iconBg: AppColors.warningBg,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // ── Revenue bar chart ──────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Revenue overview',
                        subtitle: 'Sales per period',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _RevenueBarChart(data: state.sales),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Order trend line chart ─────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Order volume',
                        subtitle: 'Number of orders per period',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: _OrderTrendChart(data: state.sales),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Top items ─────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Top selling items',
                        subtitle: 'Last 30 days',
                      ),
                      const SizedBox(height: 14),
                      ...state.topItems.asMap().entries.map((e) =>
                        _TopItemRow(
                          item: e.value,
                          rank: e.key + 1,
                          maxSold: state.topItems.first.quantitySold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue bar chart ─────────────────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final List<SalesPoint> data;
  const _RevenueBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 20000.0
        : data.map((d) => d.amount).reduce((a, b) => a > b ? a : b) * 1.25;

    return BarChart(BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
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
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 44,
          getTitlesWidget: (v, _) => Text(
            '₱${(v / 1000).toStringAsFixed(0)}k',
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary),
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
          toY:   e.value.amount,
          color: e.key == 5 ? AppColors.primary : AppColors.primaryLight,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        )],
      )).toList(),
    ));
  }
}

// ── Order trend line chart ────────────────────────────────────
class _OrderTrendChart extends StatelessWidget {
  final List<SalesPoint> data;
  const _OrderTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            '${data[s.x.toInt()].label}: ${data[s.x.toInt()].orderCount} orders',
            const TextStyle(color: Colors.white, fontSize: 11),
          )).toList(),
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              v.toInt() < data.length ? data[v.toInt()].label : '',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, _) => Text('${v.toInt()}',
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary)),
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
      lineBarsData: [LineChartBarData(
        spots: data.asMap().entries.map((e) =>
          FlSpot(e.key.toDouble(), e.value.orderCount.toDouble()),
        ).toList(),
        isCurved: true,
        color: AppColors.success,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true, color: AppColors.success.withOpacity(0.08)),
      )],
    ));
  }
}

// ── Top item row ──────────────────────────────────────────────
class _TopItemRow extends StatelessWidget {
  final ReportTopItem item;
  final int rank, maxSold;
  const _TopItemRow({
    required this.item, required this.rank, required this.maxSold,
  });

  static const _colors = [
    AppColors.primary, AppColors.info,
    AppColors.success, AppColors.warning, AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[(rank - 1) % _colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text('$rank', style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.name, style: AppText.bodyMedium)),
          Text('${item.quantitySold} sold', style: AppText.small),
          const SizedBox(width: 10),
          Text(_cur.format(item.revenue), style: AppText.bodyMedium),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.quantitySold / maxSold,
            minHeight: 4,
            backgroundColor: color.withOpacity(0.1),
            color: color,
          ),
        ),
      ]),
    );
  }
}