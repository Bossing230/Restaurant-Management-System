# RMS App Completion TODO

## Phase 1: Admin Dashboard (Current)
- [ ] Implement lib/dashboard_bloc.dart (DashboardBloc with summary, sales data, alerts)
- [ ] Create lib/frontend/features/admin_dashboard.dart (metrics cards, charts, recent orders, alerts)
- [ ] Update lib/frontend/core/shared_widgets.dart (add MetricCard, ChartWidget, AlertBanner)
- [ ] Update lib/frontend/core/api_constant.dart (add dashboard endpoints)
- [ ] Complete lib/menu_bloc.dart (add item form logic)

## Phase 2: Integrations & Other Dashboards
- [ ] Integrate dashboard with orders_bloc.dart, inventory_bloc.dart
- [ ] Complete cashier_dashboard.dart, manager_dashboard.dart
- [ ] Role-based access in app_router.dart

## Phase 3: Backend
- [ ] Create lib/backend/server.dart (Dart shelf server with mock DB)
- [ ] Database schema & endpoints

## Phase 4: Testing & Polish
- [ ] flutter pub get
- [ ] flutter analyze & test
- [ ] Setup instructions in README.md

Current progress: Starting Phase 1 Step 1
