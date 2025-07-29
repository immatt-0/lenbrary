import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';
import '../widgets/settings_menu_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ResponsiveWidget {
  final _formKey = GlobalKey<FormState>();
  final _loginInputController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _loginInputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ApiService.login(
          usernameOrEmail: _loginInputController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Navigate to success screen
        Navigator.pushReplacementNamed(context, '/success');
      } catch (e) {
        setState(() {
          // The error message from ApiService.login is already properly decoded
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          top: getResponsiveSpacing(16.0), 
          right: getResponsiveSpacing(8.0)
        ),
        child: const SettingsMenuButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: getResponsivePadding(all: 24.0),
                child: Card(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ResponsiveService.cardMaxWidth),
                    child: Padding(
                      padding: getResponsivePadding(all: 32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            Icon(
                              Icons.menu_book_rounded,
                              size: getResponsiveIconSize(64),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // App title
                            Text(
                              AppLocalizations.of(context)!.appTitle,
                              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                fontSize: 32.0,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: getResponsiveSpacing(32.0)),

                            // Username or Email field
                            ResponsiveTextField(
                              controller: _loginInputController,
                              labelText: AppLocalizations.of(context)!.usernameOrEmail,
                              hintText: ResponsiveService.isSmallPhone 
                                  ? AppLocalizations.of(context)!.loginHintShort
                                  : AppLocalizations.of(context)!.loginHintLong,
                              prefixIcon: Icon(Icons.person_outline),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterUsernameOrEmail;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Password field
                            ResponsiveTextField(
                              controller: _passwordController,
                              labelText: AppLocalizations.of(context)!.password,
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterPassword;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(24.0)),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: getResponsivePadding(all: 12.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1),
                                  borderRadius: getResponsiveBorderRadius(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            if (_errorMessage != null)
                              SizedBox(height: getResponsiveSpacing(16.0)),

                            // Login button
                            ResponsiveButton(
                              text: AppLocalizations.of(context)!.authentication,
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Register link
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                AppLocalizations.of(context)!.noAccountRegister,
                                style: ResponsiveTextStyles.getResponsiveTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
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
        ),
      ),
    );
  }
}
