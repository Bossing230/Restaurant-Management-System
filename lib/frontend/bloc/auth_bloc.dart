import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:rms_app/frontend/core/api_client.dart';
import 'package:rms_app/frontend/core/api_constant.dart';
import 'package:rms_app/frontend/core/app_theme.dart';
// ════════════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════════════
class UserModel extends Equatable {
  final String id, name, email, role;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:        j['id'].toString(),
    name:      j['name']  as String,
    email:     j['email'] as String,
    role:      j['role']  as String,
    avatarUrl: j['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
  };

  String get initials => name
      .trim()
      .split(' ')
      .map((e) => e.isEmpty ? '' : e[0].toUpperCase())
      .take(2)
      .join();

  @override
  List<Object?> get props => [id, role];
}

// ════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AuthCheckEvent  extends AuthEvent {}
class AuthLogoutEvent extends AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email, password;
  AuthLoginEvent(this.email, this.password);
  @override List<Object?> get props => [email, password];
}

// ════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial         extends AuthState {}
class AuthLoading         extends AuthState {}
class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage;
  UserModel? currentUser;

  AuthBloc({required ApiClient apiClient, required FlutterSecureStorage storage})
      : _api = apiClient,
        _storage = storage,
        super(AuthInitial()) {
    on<AuthCheckEvent>(_onCheck);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckEvent _, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token    = await _storage.read(key: AppConstants.tokenKey);
      final userData = await _storage.read(key: AppConstants.userKey);
      if (token != null && userData != null) {
        currentUser = UserModel.fromJson(jsonDecode(userData) as Map<String, dynamic>);
        emit(AuthAuthenticated(currentUser!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _api.dio.post(
        ApiConstants.login,
        data: {'email': event.email.trim(), 'password': event.password},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      await _storage.write(key: AppConstants.tokenKey,   value: data['token'] as String);
      await _storage.write(key: AppConstants.refreshKey, value: data['refresh_token'] as String);
      currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(currentUser!.toJson()),
      );
      emit(AuthAuthenticated(currentUser!));
    } catch (e) {
      emit(AuthError('Invalid credentials. Please try again.'));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent _, Emitter<AuthState> emit) async {
    await _storage.deleteAll();
    currentUser = null;
    emit(AuthUnauthenticated());
  }
}

// ════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form    = GlobalKey<FormState>();
  final _email   = TextEditingController(text: 'admin@restaurant.com');
  final _pass    = TextEditingController(text: 'password123');
  bool _obscure  = true;

  // Quick login roles
  static const _roles = [
    ('Admin',   'admin@restaurant.com',   Icons.admin_panel_settings_outlined, AppColors.primary),
    ('Manager', 'manager@restaurant.com', Icons.trending_up_outlined,          AppColors.success),
    ('Cashier', 'cashier@restaurant.com', Icons.point_of_sale_outlined,        AppColors.info),
    ('Kitchen', 'kitchen@restaurant.com', Icons.soup_kitchen_outlined,         Color(0xFF9C27B0)),
  ];

  void _submit() {
    if (_form.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginEvent(_email.text.trim(), _pass.text),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          final route = switch (state.user.role) {
            'admin'   => '/dashboard/admin',
            'manager' => '/dashboard/manager',
            'cashier' => '/pos',
            'kitchen' => '/kitchen',
            _         => '/dashboard/admin',
          };
          ctx.go(route);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text('Welcome back', style: AppText.h2),
                const SizedBox(height: 6),
                Text('Sign in to RestaurantOS', style: AppText.small),
                const SizedBox(height: 32),

                // Quick role selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick login', style: AppText.label),
                      const SizedBox(height: 10),
                      Row(
                        children: _roles.map((r) {
                          final (label, email, icon, color) = r;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _email.text = email;
                                _pass.text  = 'password123';
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: (color).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: color.withOpacity(0.25)),
                                ),
                                child: Column(children: [
                                  Icon(icon, size: 18, color: color),
                                  const SizedBox(height: 4),
                                  Text(label, style: TextStyle(
                                    fontSize: 10, color: color,
                                    fontWeight: FontWeight.w600,
                                  )),
                                ]),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Login form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pass,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (ctx, state) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading ? null : _submit,
                            child: state is AuthLoading
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Sign in'),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}