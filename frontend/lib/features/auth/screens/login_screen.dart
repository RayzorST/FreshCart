import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/auth/bloc/login_bloc.dart';
import 'package:client/features/auth/bloc/auth_bloc.dart';
import 'package:client/core/di/di.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LoginBloc>(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.read<AuthBloc>().add(LoggedIn(user: state.user));
            context.go('/');
            AppSnackbar.showSuccess(context: context, message: 'Успешный вход');
          } else if (state is LoginFailure) {
            AppSnackbar.showError(context: context, message: state.error);
          }
        },
        child: const _LoginScreenContent(),
      ),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => __LoginScreenContentState();
}

class __LoginScreenContentState extends State<_LoginScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    Widget loginForm = Padding(
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
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state is LoginLoading ? null : _submitForm,
                    child: state is LoginLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Войти'),
                  ),
                );
              },
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
    );

    if (isWideScreen) {
      loginForm = Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Card(
            elevation: 4,
            child: loginForm,
          ),
        ),
      );
    }

    return Scaffold(
      body: loginForm,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginButtonPressed(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}