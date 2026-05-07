import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  static const _staff = [
    ('Maria Santos',   'Cashier', 'online', 14, 6840.0),
    ('Jose Reyes',     'Waiter',  'online', 22, 9020.0),
    ('Ana Cruz',       'Kitchen', 'break',   0,    0.0),
    ('Liza Garcia',    'Cashier', 'online',  9, 3780.0),
    ('Pedro Cruz',     'Kitchen', 'online',  0,    0.0),
    ('Rosa Bautista',  'Manager', 'online',  0,    0.0),
    ('Carlo Reyes',    'Waiter',  'off',      0,    0.0),
  ];

  @override
  Widget build(BuildContext context) {
    final _cur = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Column(children: [
      // Search + add
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Expanded(
            child: AppSearchBar(hint: 'Search employees...'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add employee'),
            onPressed: () => _showAddDialog(context),
          ),
        ]),
      ),

      // Stats strip
      Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          _StatChip('${_staff.length} total',
              AppColors.textSecondary, AppColors.bgInput),
          const SizedBox(width: 8),
          _StatChip(
            '${_staff.where((s) => s.$3 == "online").length} online',
            AppColors.success, AppColors.successBg),
          const SizedBox(width: 8),
          _StatChip(
            '${_staff.where((s) => s.$3 == "break").length} on break',
            AppColors.warning, AppColors.warningBg),
        ]),
      ),

      // Employee list
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _staff.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final (name, role, status, orders, sales) = _staff[i];
            final dotColor = status == 'online'
                ? AppColors.success
                : status == 'break'
                    ? AppColors.warning
                    : AppColors.textHint;

            return AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                UserAvatar(name: name, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.bodyMedium),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(role, style: AppText.small),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: dotColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status, style: TextStyle(
                          fontSize: 10, color: dotColor,
                          fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ],
                )),
                if (sales > 0)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_cur.format(sales), style: AppText.bodyMedium),
                    Text('$orders orders', style: AppText.small),
                  ]),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AppColors.textSecondary),
                  itemBuilder: (_) => [
                    'View profile',
                    'Edit details',
                    'Change role',
                    'Deactivate',
                  ].map((a) => PopupMenuItem(
                    child: Text(a, style: AppText.body),
                  )).toList(),
                ),
              ]),
            );
          },
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
              const Text('Add employee', style: AppText.h4),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'First name'))),
                const SizedBox(width: 12),
                const Expanded(child: TextField(
                  decoration: InputDecoration(labelText: 'Last name'))),
              ]),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              )),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(
                labelText: 'Temporary password',
                prefixIcon: Icon(Icons.lock_outline, size: 18),
              ), obscureText: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['admin','manager','cashier','kitchen']
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r[0].toUpperCase() + r.substring(1)),
                        ))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Add employee'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _StatChip(String label, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
  child: Text(label, style: TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
);