import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiService apiService;
  bool _isLoading = false;
  String? _errorMessage;

  LoginViewModel({required this.apiService});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    if (email.isEmpty) {
      _errorMessage = "Please enter an email address";
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Login failed: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController(text: "demo@antigravity.ai");
  final _passwordController = TextEditingController(text: "password123");

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final apiService = Provider.of<ApiService>(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => LoginViewModel(apiService: apiService),
          child: Consumer<LoginViewModel>(
            builder: (context, model, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    const Spacer(),
                    // Top Logo / Header
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.positive.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          "📈",
                          style: TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Wealth Tracker",
                      style: theme.titleStyle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Track valuations and passive dividend incomes",
                      style: theme.subtitleStyle,
                    ),
                    const SizedBox(height: 48),

                    // Inputs card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            style: TextStyle(color: theme.text),
                            decoration: InputDecoration(
                              labelText: "Email Address",
                              labelStyle: TextStyle(color: theme.subtext),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.border),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.positive),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: theme.text),
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: theme.subtext),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.border),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.positive),
                              ),
                            ),
                          ),
                          if (model.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              model.errorMessage!,
                              style: const TextStyle(color: AppColors.negative, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: model.isLoading
                                ? null
                                : () async {
                                    final success = await model.signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                    if (!context.mounted) return;
                                    if (success) {
                                      context.replace("/dashboard");
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.positive,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: model.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Theme selector switch pinned at the bottom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                theme.isDark ? "🌙" : "☀️",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Dark Mode",
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: theme.isDark,
                            activeThumbColor: AppColors.positive,
                            onChanged: (_) => theme.toggleTheme(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
