import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:homeapp/l10n/app_localizations.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

/// Handles user authentication (Login/Signup).
///
/// Interacts with Supabase Auth to authenticate users and triggers the remote RPC
/// `ensure_user_household_and_default_lists` upon a successful login or signup
/// to ensure the backend environment (households, lists) is ready down the line.
class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLogin = false;
  bool _isLoading = false;
  OAuthProvider? _activeProvider;
  StreamSubscription<AuthState>? _authStateSubscription;
  String? _bootstrappedUserId;

  @override
  void initState() {
    super.initState();
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        _ensureUserBootstrapData();
      }
    });
  }

  String _normalizedEmail(String emailText) {
    return emailText.contains('@') ? emailText : '$emailText@test.com';
  }

  Future<void> _ensureUserBootstrapData({
    String? firstName,
    String? lastName,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _bootstrappedUserId == user.id) {
      return;
    }

    await Supabase.instance.client.rpc(
      'ensure_user_household_and_default_lists',
      params: {
        'u_first_name': firstName ?? '',
        'u_last_name': lastName ?? '',
      },
    );

    _bootstrappedUserId = user.id;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final emailText = _emailController.text.trim();
      final passwordText = _passwordController.text.trim();
      final firstNameText = _firstNameController.text.trim();
      final lastNameText = _lastNameController.text.trim();

      // Developer test account fix: if they use 'developer' without domain, append a domain
      final email = _normalizedEmail(emailText);

      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: passwordText,
        );
        // Ensure required household/list records exist before entering app.
        await _ensureUserBootstrapData();

        if (!mounted) return;
        context.go('/home-page');
      } else {
        if (firstNameText.isEmpty || lastNameText.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.authNameRequired)),
          );
          return;
        }

        // Sign up
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: passwordText,
        );

        final user = res.user;
        if (user != null) {
          // Use provided names only on first bootstrap; function is idempotent.
          await _ensureUserBootstrapData(
            firstName: firstNameText,
            lastName: lastNameText,
          );
        }

        if (!mounted) return;
        if (res.session == null) {
            // Confirm-email projects return no session until verification.
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.authSignupSuccess),
            ));
            setState(() => _isLogin = true);
          } else {
          context.go('/home-page');
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .authUnexpectedError(error.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _providerLabel(AppLocalizations l10n, OAuthProvider provider) {
    if (provider == OAuthProvider.google) {
      return l10n.authGoogle;
    }
    return l10n.authApple;
  }

  Future<void> _continueWithProvider(OAuthProvider provider) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _activeProvider = provider;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final providerLabel = _providerLabel(l10n, provider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authContinueInBrowser(providerLabel))),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .authUnexpectedError(error.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeProvider = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.secondary.withValues(alpha: 0.06),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 42,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appTitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? l10n.authLoginSubtitle
                              : l10n.authRegisterSubtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text(l10n.authRegister),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text(l10n.authLogin),
                              icon: const Icon(Icons.login_rounded),
                            ),
                          ],
                          selected: {_isLogin},
                          onSelectionChanged: _isLoading
                              ? null
                              : (selection) {
                                  setState(() {
                                    _isLogin = selection.first;
                                  });
                                },
                        ),
                        const SizedBox(height: 18),
                        if (!_isLogin) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.authFirstName,
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.authSurname,
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.authEmail,
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: l10n.authPassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _submit();
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_isLoading
                              ? l10n.authPleaseWait
                              : (_isLogin ? l10n.authLogin : l10n.authRegister)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: Divider(color: colorScheme.outline)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                l10n.authOrContinueWith,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            Expanded(child: Divider(color: colorScheme.outline)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _continueWithProvider(OAuthProvider.google),
                          icon: _activeProvider == OAuthProvider.google
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const FaIcon(FontAwesomeIcons.google, size: 16),
                          label: Text(l10n.authContinueWithGoogle),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _continueWithProvider(OAuthProvider.apple),
                          icon: _activeProvider == OAuthProvider.apple
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const FaIcon(FontAwesomeIcons.apple, size: 16),
                          label: Text(l10n.authContinueWithApple),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                          child: Text(_isLogin
                              ? l10n.authSignupPrompt
                              : l10n.authLoginPrompt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
