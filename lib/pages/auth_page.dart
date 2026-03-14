import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final emailText = _emailController.text.trim();
      final passwordText = _passwordController.text.trim();

      // Developer test account fix: if they use 'developer' without domain, append a domain
      final email = emailText.contains('@') ? emailText : '$emailText@test.com';

      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: passwordText,
        );
        // Ensure required household/list records exist before entering app.
        await Supabase.instance.client.rpc('ensure_user_household_and_default_lists');

        if (!mounted) return;
        if (mounted) context.go('/home-page');
      } else {
        // Sign up
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: passwordText,
        );

        final user = res.user;
        if (user != null) {
          // Use username only on first bootstrap; function is idempotent.
          await Supabase.instance.client.rpc(
            'ensure_user_household_and_default_lists',
            params: {'u_username': _usernameController.text.trim()},
          );
        }

        if (!mounted) return;
        if (mounted) {
          if (res.session == null) {
            // Confirm-email projects return no session until verification.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
               content: Text('Registration successful! Please check your email to verify your account.'),
            ));
            setState(() => _isLogin = true);
          } else {
            context.go('/home-page');
          }
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unexpected error occurred: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isLogin)
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading
                    ? 'Please wait...'
                    : (_isLogin ? 'Login' : 'Register')),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin
                    ? 'Don\'t have an account? Register'
                    : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
