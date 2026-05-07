// ── API endpoint constants ────────────────────────────────────
class ApiConstants {
  // Change to your LAN IP when running on a physical device
  // Android emulator  → http://10.0.2.2:3000/api/v1
  // iOS simulator     → http://localhost:3000/api/v1
  // Physical device   → http://<your-LAN-IP>:3000/api/v1
  static const baseUrl        = 'http://10.0.2.2:3000/api/v1';
  static const connectTimeout = 30000;
  static const receiveTimeout = 30000;
 
  // Auth
  static const login        = '/auth/login';
  static const logout       = '/auth/logout';
  static const refreshToken = '/auth/refresh';
  static const me           = '/auth/me';
 
  // Dashboard
  static const dashboardSummary  = '/dashboard/summary';
  static const dashboardSales    = '/dashboard/sales';
  static const dashboardAlerts   = '/dashboard/alerts';
  static const dashboardTopItems = '/dashboard/top-items';
 
  // Core resources
  static const menu           = '/menu';
  static const menuCategories = '/menu/categories';
  static const orders         = '/orders';
  static const tables         = '/tables';
  static const inventory      = '/inventory';
  static const customers      = '/customers';
  static const reservations   = '/reservations';
  static const reports        = '/reports';
  static const salesReport    = '/reports/sales';
  static const topItems       = '/reports/top-items';
  static const reportsSummary = '/reports/summary';
  static const staff          = '/staff';
  static const settingsUrl    = '/settings/restaurant';
}
 
// ── App-wide constants ────────────────────────────────────────
class AppConstants {
  static const tokenKey   = 'auth_token';
  static const refreshKey = 'refresh_token';
  static const userKey    = 'user_data';
  static const taxRate    = 0.12; // 12% Philippine VAT
}