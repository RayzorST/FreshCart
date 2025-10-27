import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FreshCart',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Войдите в свой аккаунт',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : () async {  // ← ИЗМЕНИ ЭТУ СТРОКУ
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);  // ← ДОБАВЬ
                      try {
                        final response = await ApiClient.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                        
                        // Сохраняем токен
                        ApiClient.setToken(response['access_token']);
                        
                        // Переходим в основное приложение
                        context.go('/');
                      } catch (e) {
                        // Показываем ошибку
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: $e')),
                        );
                      } finally {
                        setState(() => _isLoading = false);  // ← ДОБАВЬ
                      }
                    }
                  },
                  child: _isLoading ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ): const Text('Войти'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.push('/register');
                },
                child: const Text('Создать аккаунт'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}