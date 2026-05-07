import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/tables_bloc.dart';
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TablesBloc, TablesState>(
      builder: (ctx, state) {
        if (state is TablesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is TablesLoaded) {
          return _TablesBody(state: state);
        }
        return const SizedBox();
      },
    );
  }
}

class _TablesBody extends StatelessWidget {
  final TablesLoaded state;
  const _TablesBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<TablesBloc>().add(TablesRefreshEvent()),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Status summary strip
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill('${state.tables.length} total',
                        AppColors.textSecondary, AppColors.bgInput),
                    _StatusPill('${state.available} available',
                        AppColors.success, AppColors.successBg),
                    _StatusPill('${state.occupied} occupied',
                        AppColors.danger, AppColors.dangerBg),
                    _StatusPill('${state.reserved} reserved',
                        AppColors.warning, AppColors.warningBg),
                  ],
                ),
                const SizedBox(height: 16),

                // Table grid
                LayoutBuilder(builder: (_, c) {
                  final cols = c.maxWidth > 700 ? 5
                      : c.maxWidth > 480 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: state.tables.length,
                    itemBuilder: (_, i) =>
                        _TableCard(table: state.tables[i]),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  const _TableCard({required this.table});

  Color get _color => switch (table.status) {
    'available' => AppColors.success,
    'occupied'  => AppColors.danger,
    'reserved'  => AppColors.warning,
    _           => AppColors.textSecondary,
  };

  Color get _bg => switch (table.status) {
    'available' => AppColors.successBg,
    'occupied'  => AppColors.dangerBg,
    'reserved'  => AppColors.warningBg,
    _           => AppColors.bgInput,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showModal(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(table.number,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: _color)),
              Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
            ]),
            const Spacer(),
            Text(table.status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: _color, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.people_outline, size: 12,
                  color: _color.withOpacity(0.7)),
              const SizedBox(width: 3),
              Text('${table.capacity} seats',
                style: TextStyle(fontSize: 11,
                    color: _color.withOpacity(0.8))),
            ]),
            if (table.waiterName != null) ...[
              const SizedBox(height: 3),
              Text(table.waiterName!,
                style: TextStyle(fontSize: 10,
                    color: _color.withOpacity(0.7)),
                overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TableModal(
        table: table,
        onStatusChange: (s) =>
            context.read<TablesBloc>().add(TableUpdateStatusEvent(table.id, s)),
      ),
    );
  }
}

class _TableModal extends StatelessWidget {
  final TableModel table;
  final void Function(String) onStatusChange;
  const _TableModal({required this.table, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Text('Table ${table.number}', style: AppText.h3),
          const Spacer(),
          StatusBadge(status: table.status),
        ]),
        const SizedBox(height: 6),
        Text('${table.capacity} seats · ${table.section ?? "indoor"}',
            style: AppText.small),
        const SizedBox(height: 20),
        const Text('Change status', style: AppText.label),
        const SizedBox(height: 10),
        Row(children: [
          for (final s in ['available', 'occupied', 'reserved', 'cleaning'])
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: OutlinedButton(
                onPressed: () {
                  onStatusChange(s);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: table.status == s
                      ? AppColors.primary : AppColors.textSecondary,
                  side: BorderSide(
                    color: table.status == s
                        ? AppColors.primary : AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(s, style: const TextStyle(fontSize: 11)),
              ),
            )),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New order for this table'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

Widget _StatusPill(String label, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
  child: Text(label,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
);