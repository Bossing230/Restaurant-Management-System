import 'package:flutter/material.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
import 'package:rms_app/frontend/core/shared_widgets.dart';

// ════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tab bar
      Container(
        color: AppColors.bgCard,
        child: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppText.bodyMedium,
          unselectedLabelStyle: AppText.body,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Restaurant'),
            Tab(text: 'Permissions'),
          ],
        ),
      ),

      // Tab views
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: [
            _ProfileTab(),
            _RestaurantTab(),
            _PermissionsTab(),
          ],
        ),
      ),
    ]);
  }
}

// ── Profile tab ───────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profile settings', style: AppText.h4),
          const SizedBox(height: 6),
          const Text('Update your personal information and password.',
              style: AppText.small),
          const SizedBox(height: 24),

          // Avatar
          Center(child: Stack(children: [
            const UserAvatar(name: 'Admin User', size: 80),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 14, color: Colors.white),
              ),
            ),
          ])),
          const SizedBox(height: 24),

          Row(children: [
            const Expanded(child: TextField(
              decoration: InputDecoration(labelText: 'First name'),
            )),
            const SizedBox(width: 16),
            const Expanded(child: TextField(
              decoration: InputDecoration(labelText: 'Last name'),
            )),
          ]),
          const SizedBox(height: 14),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Current password',
              prefixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Save changes'),
          ),
        ]),
      ),
    );
  }
}

// ── Restaurant tab ────────────────────────────────────────────
class _RestaurantTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Restaurant information', style: AppText.h4),
          const SizedBox(height: 6),
          const Text('Update your restaurant details and configuration.',
              style: AppText.small),
          const SizedBox(height: 24),

          const TextField(
            decoration: InputDecoration(
              labelText: 'Restaurant name',
              prefixIcon: Icon(Icons.restaurant_menu_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: TextField(
              decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
            )),
            const SizedBox(width: 16),
            const Expanded(child: TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            )),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: TextField(
              decoration: InputDecoration(
                labelText: 'Tax rate (%)',
                prefixIcon: Icon(Icons.percent_outlined, size: 18),
              ),
              keyboardType: TextInputType.number,
            )),
            const SizedBox(width: 16),
            const Expanded(child: TextField(
              decoration: InputDecoration(
                labelText: 'Currency symbol',
                prefixIcon: Icon(Icons.attach_money_outlined, size: 18),
              ),
            )),
          ]),
          const SizedBox(height: 14),

          // System toggles
          AppCard(
            child: Column(children: [
              _ToggleTile(
                title: 'Enable loyalty points',
                subtitle: 'Award points to customers on each order',
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1),
              _ToggleTile(
                title: 'Auto-deduct inventory',
                subtitle: 'Deduct stock automatically when orders are placed',
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1),
              _ToggleTile(
                title: 'Low stock notifications',
                subtitle: 'Show alerts when items fall below 30%',
                value: true,
                onChanged: (_) {},
              ),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Update info'),
          ),
        ]),
      ),
    );
  }
}

// ── Permissions tab ───────────────────────────────────────────
class _PermissionsTab extends StatelessWidget {
  static const _roles = ['Admin', 'Manager', 'Cashier', 'Kitchen'];
  static const _perms = [
    'View dashboard',
    'Manage orders',
    'Manage menu',
    'Manage inventory',
    'View reports',
    'Manage reservations',
    'Manage staff',
  ];

  // Default permissions per role
  static const _defaults = {
    'Admin':   [true,  true,  true,  true,  true,  true,  true],
    'Manager': [true,  true,  true,  true,  true,  true,  false],
    'Cashier': [false, true,  false, false, false, true,  false],
    'Kitchen': [false, false, false, false, false, false, false],
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Role permissions', style: AppText.h4),
        const SizedBox(height: 6),
        const Text('Configure what each role can access in the system.',
            style: AppText.small),
        const SizedBox(height: 20),

        ..._roles.map((role) {
          final perms = _defaults[role]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(role, style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ..._perms.asMap().entries.map((e) => Row(children: [
                    Checkbox(
                      value: perms[e.key],
                      onChanged: role == 'Admin' ? null : (_) {},
                      activeColor: AppColors.primary,
                    ),
                    Text(e.value, style: AppText.body),
                  ])),
                ],
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.bodyMedium),
            const SizedBox(height: 2),
            Text(subtitle, style: AppText.small),
          ],
        )),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ]),
    );
  }
}