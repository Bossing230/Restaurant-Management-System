import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';
import 'package:rms_app/frontend/bloc/inventory_bloc.dart';

final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
final _dateFmt = DateFormat('MMM d, yyyy');

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  static const _avatarBgs = [
    AppColors.primaryLight,
    AppColors.infoBg,
    AppColors.successBg,
    AppColors.warningBg,
    Color(0xFFEEEDFE),
    Color(0xFFFBEAF0),
  ];
  static const _avatarFgs = [
    AppColors.primaryDark,
    AppColors.info,
    AppColors.success,
    Color(0xFF854F0B),
    Color(0xFF534AB7),
    Color(0xFF993556),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersBloc, CustomersState>(
      builder: (ctx, state) {
        if (state is CustomersLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is CustomersLoaded) {
          return _CustomersBody(
            state: state,
            avatarBgs: _avatarBgs,
            avatarFgs: _avatarFgs,
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _CustomersBody extends StatelessWidget {
  final CustomersLoaded state;
  final List<Color> avatarBgs, avatarFgs;
  const _CustomersBody({
    required this.state,
    required this.avatarBgs,
    required this.avatarFgs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Search + add ──────────────────────────────────
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: AppSearchBar(
              hint: 'Search by name, email, or phone...',
              onChanged: (q) => context.read<CustomersBloc>()
                  .add(CustomersSearchEvent(q)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add customer'),
            onPressed: () => _showAddDialog(context),
          ),
        ]),
      ),

      // ── Stats strip ───────────────────────────────────
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          _StatChip('${state.all.length} total',
              AppColors.textSecondary, AppColors.bgInput),
          const SizedBox(width: 8),
          _StatChip(
            '${state.all.where((c) => c.loyaltyPoints > 200).length} VIP',
            const Color(0xFF854F0B), AppColors.warningBg),
          const SizedBox(width: 8),
          _StatChip(
            '${_cur.format(state.all.fold(0.0, (a, c) => a + c.totalSpent))} spent',
            AppColors.success, AppColors.successBg),
        ]),
      ),

      // ── Customer list ─────────────────────────────────
      Expanded(
        child: state.filtered.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: 'No customers found',
              subtitle: 'Try a different search term',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => context.read<CustomersBloc>()
                  .add(CustomersLoadEvent()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final idx = i % avatarBgs.length;
                  return _CustomerCard(
                    customer: state.filtered[i],
                    avatarBg: avatarBgs[idx],
                    avatarFg: avatarFgs[idx],
                    onTap: () => _showDetail(
                      context,
                      state.filtered[i],
                      avatarBgs[idx],
                      avatarFgs[idx],
                    ),
                  );
                },
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
              const Text('Add customer', style: AppText.h4),
              const SizedBox(height: 20),
              const TextField(decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              )),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Add customer'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext ctx, CustomerModel c, Color bg, Color fg) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(
          customer: c, avatarBg: bg, avatarFg: fg),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final Color avatarBg, avatarFg;
  final VoidCallback onTap;
  const _CustomerCard({
    required this.customer, required this.avatarBg,
    required this.avatarFg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: avatarBg,
          child: Text(c.initials, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: avatarFg)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name, style: AppText.bodyMedium),
            if (c.email != null)
              Text(c.email!, style: AppText.small,
                  overflow: TextOverflow.ellipsis),
            if (c.phone != null)
              Text(c.phone!, style: AppText.small),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_cur.format(c.totalSpent), style: AppText.bodyMedium),
          Text('${c.totalOrders} orders', style: AppText.small),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, size: 10, color: Color(0xFF854F0B)),
              const SizedBox(width: 3),
              Text('${c.loyaltyPoints} pts', style: const TextStyle(
                fontSize: 10, color: Color(0xFF854F0B),
                fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      ]),
    );
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  final CustomerModel customer;
  final Color avatarBg, avatarFg;
  const _CustomerDetailSheet({
    required this.customer, required this.avatarBg, required this.avatarFg,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),

        // Avatar + name
        CircleAvatar(
          radius: 34,
          backgroundColor: avatarBg,
          child: Text(c.initials, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: avatarFg)),
        ),
        const SizedBox(height: 12),
        Text(c.name, style: AppText.h3),
        if (c.email != null)
          Text(c.email!, style: AppText.small),
        const SizedBox(height: 20),

        // Stats row
        Row(children: [
          Expanded(child: _StatBox(_cur.format(c.totalSpent), 'Total spent')),
          Expanded(child: _StatBox('${c.totalOrders}', 'Orders')),
          Expanded(child: _StatBox('${c.loyaltyPoints}', 'Points')),
        ]),
        const SizedBox(height: 16),

        // Contact info
        if (c.phone != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.phone_outlined,
                color: AppColors.textSecondary, size: 18),
            title: Text(c.phone!, style: AppText.body),
          ),
        if (c.lastVisit != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 18),
            title: Text(
              'Last visit: ${_dateFmt.format(c.lastVisit!)}',
              style: AppText.body,
            ),
          ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.star_outline, size: 16),
            label: const Text('Add points'),
            onPressed: () => Navigator.pop(context),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Order history'),
            onPressed: () => Navigator.pop(context),
          )),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}

Widget _StatBox(String value, String label) => Column(children: [
  Text(value, style: AppText.h3),
  const SizedBox(height: 2),
  Text(label, style: AppText.small),
]);

Widget _StatChip(String label, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
  child: Text(label, style: TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
);