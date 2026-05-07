import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';

final _timeFmt = DateFormat('h:mm a');
final _dateFmt = DateFormat('MMM d');

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  static const _filters = ['Today', 'All', 'Upcoming', 'Cancelled'];
  static const _statuses = [
    'confirmed', 'seated', 'completed', 'cancelled', 'no-show',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationsBloc, ReservationsState>(
      builder: (ctx, state) {
        if (state is ReservationsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is ReservationsLoaded) {
          return _ReservationsBody(
            state: state,
            filters: _filters,
            statuses: _statuses,
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _ReservationsBody extends StatelessWidget {
  final ReservationsLoaded state;
  final List<String> filters, statuses;
  const _ReservationsBody({
    required this.state,
    required this.filters,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ─────────────────────────────────────
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Filter tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final active = f.toLowerCase() == state.activeFilter;
                  return GestureDetector(
                    onTap: () => context.read<ReservationsBloc>()
                        .add(ReservationsSetFilterEvent(f.toLowerCase())),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary : AppColors.bgInput,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(f, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: active
                            ? Colors.white : AppColors.textSecondary,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New booking'),
            onPressed: () => _showBookingDialog(context),
          ),
        ]),
      ),

      // ── List ────────────────────────────────────────
      Expanded(
        child: state.reservations.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No reservations',
              subtitle: 'No bookings for this period',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => context.read<ReservationsBloc>()
                  .add(ReservationsLoadEvent()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.reservations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = state.reservations[i];
                  return _ReservationCard(
                    reservation: r,
                    statuses: statuses,
                    onStatusChange: (s) => context
                        .read<ReservationsBloc>()
                        .add(ReservationsUpdateStatusEvent(r.id, s)),
                  );
                },
              ),
            ),
      ),
    ]);
  }

  void _showBookingDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => const _BookingDialog(),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final List<String> statuses;
  final void Function(String) onStatusChange;
  const _ReservationCard({
    required this.reservation,
    required this.statuses,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final (bg, fg) = switch (r.status) {
      'confirmed' => (AppColors.infoBg,   AppColors.info),
      'seated'    => (AppColors.successBg, AppColors.success),
      'completed' => (const Color(0xFFF3E5F5), const Color(0xFF6C3483)),
      'cancelled' => (AppColors.dangerBg,  AppColors.danger),
      'no-show'   => (const Color(0xFFFAFAFA), AppColors.textSecondary),
      _           => (AppColors.bgInput,   AppColors.textSecondary),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Time block
        Container(
          width: 58, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_timeFmt.format(r.reservedAt),
              style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: fg)),
            Text(_dateFmt.format(r.reservedAt),
              style: TextStyle(fontSize: 10,
                  color: fg.withOpacity(0.7))),
          ]),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(r.customerName ?? 'Walk-in',
                  style: AppText.bodyMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline,
                      size: 10, color: AppColors.primaryDark),
                  const SizedBox(width: 3),
                  Text('${r.partySize}', style: const TextStyle(
                    fontSize: 10, color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            if (r.tableNumber != null)
              Text('Table ${r.tableNumber}', style: AppText.small),
            if (r.customerPhone != null)
              Text(r.customerPhone!, style: AppText.small),
            if (r.notes != null)
              Text(r.notes!,
                style: AppText.small.copyWith(
                    fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis),
          ],
        )),

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
              value: r.status,
              isDense: true,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textPrimary,
                fontFamily: 'Inter'),
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
    );
  }
}

class _BookingDialog extends StatelessWidget {
  const _BookingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New reservation', style: AppText.h4),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(
              labelText: 'Customer name',
              prefixIcon: Icon(Icons.person_outline, size: 18),
            )),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined, size: 18),
            ), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: TextField(decoration: InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ))),
              const SizedBox(width: 12),
              const Expanded(child: TextField(decoration: InputDecoration(
                labelText: 'Time',
                prefixIcon: Icon(Icons.access_time_outlined, size: 18),
              ))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: TextField(decoration: InputDecoration(
                labelText: 'Table',
                prefixIcon: Icon(Icons.table_restaurant_outlined, size: 18),
              ))),
              const SizedBox(width: 12),
              const Expanded(child: TextField(
                decoration: InputDecoration(labelText: 'Party size'),
                keyboardType: TextInputType.number,
              )),
            ]),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                  labelText: 'Notes / special requests'),
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
                child: const Text('Confirm booking'),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}