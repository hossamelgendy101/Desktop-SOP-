import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/locale_service.dart';
import '../blocs/auth_bloc.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(
            _usernameCtrl.text.trim(),
            _passwordCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          } else if (state is AuthError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthLoading) {
            setState(() => _isLoading = true);
          }
        },
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width > 900)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale_rounded,
                          size: 120,
                          color: Colors.white.withOpacity(0.9),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOut),
                        const SizedBox(height: 32),
                        Text(
                          'ProPOS',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                        const SizedBox(height: 16),
                        Text(
                          localeService.localize('Complete Offline Point of Sale System', 'نظام نقاط بيع متكامل بدون إنترنت'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 3,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (MediaQuery.of(context).size.width <= 900) ...[
                            Icon(
                              Icons.point_of_sale_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ProPOS',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                          ],
                          Text(
                            localeService.localize('Welcome Back', 'مرحباً بعودتك'),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localeService.localize('Sign in to your account to continue', 'قم بتسجيل الدخول إلى حسابك للمتابعة'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              labelText: localeService.localize('Username', 'اسم المستخدم'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? localeService.localize('Username is required', 'اسم المستخدم مطلوب') : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: localeService.localize('Password', 'كلمة المرور'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? localeService.localize('Password is required', 'كلمة المرور مطلوبة') : null,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(localeService.localize('Forgot Password?', 'هل نسيت كلمة المرور؟')),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(localeService.localize('Sign In', 'تسجيل الدخول')),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              localeService.localize('Default: admin / admin123', 'الافتراضي: admin / admin123'),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
