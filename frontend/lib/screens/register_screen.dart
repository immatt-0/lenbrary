import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';
import '../widgets/settings_menu_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with ResponsiveWidget {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTeacher = false;
  String? _errorMessage;
  
  // School type options
  final List<String> _schoolTypeOptions = ['Generala', 'Liceu'];
  String? _selectedSchoolType;
  
  // Department options (for Liceu only)
  final List<String> _departmentOptions = ['N', 'SW', 'STS', 'MI', 'FILO'];
  String? _selectedDepartment;
  
  // Class options
  final List<String> _generalaClassOptions = ['V', 'VI', 'VII', 'VIII'];
  final List<String> _liceuClassOptions = ['IX', 'X', 'XI', 'XII'];
  String? _selectedClass;
  
  // Class character options (for Generala only)
  final List<String> _classCharacterOptions = ['A', 'B', 'C', 'D', 'E', 'F'];
  String? _selectedClassCharacter;

  bool _obscurePassword = true;

  // Helper method to get localized school type
  String _getLocalizedSchoolType(BuildContext context, String type) {
    switch (type) {
      case 'Generala':
        return AppLocalizations.of(context)!.schoolTypeGenerala;
      case 'Liceu':
        return AppLocalizations.of(context)!.schoolTypeLiceu;
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Form department based on school type
        String? department;
        String? formattedClass;
        String? schoolType = _selectedSchoolType;
        
        if (!_isTeacher) {
          if (_selectedSchoolType == 'Liceu') {
            department = _selectedDepartment;
            formattedClass = _selectedClass;
          } else if (_selectedSchoolType == 'Generala') {
            department = null; // No department for Generala
            // Format class like "V-A"
            formattedClass = _selectedClass != null && _selectedClassCharacter != null 
                ? "$_selectedClass-$_selectedClassCharacter" 
                : _selectedClass;
          }
        }
        
        await ApiService.register(
          password: _passwordController.text,
          email: _emailController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          schoolType: schoolType,
          department: department,
          studentClass: formattedClass,
          isTeacher: _isTeacher,
          invitationCode: _isTeacher && _invitationCodeController.text.isNotEmpty
              ? _invitationCodeController.text
              : null,
        );
        
        // After registration, automatically send verification email
        try {
          await ApiService.sendVerificationEmail();
        } catch (e) {
          // Optionally log or handle error, but continue to login
        }
        if (mounted) {
          NotificationService.showSuccess(
            context: context,
            message: AppLocalizations.of(context)!.registrationSuccess,
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        setState(() {
          String errorMsg = e.toString();
          
          // Try to extract invitation_code error from JSON response
          if (errorMsg.contains('"invitation_code"')) {
            try {
              // Extract content between "invitation_code" and the closing bracket
              final codeStart = errorMsg.indexOf('"invitation_code"');
              final valueStart = errorMsg.indexOf('[', codeStart) + 1;
              final valueEnd = errorMsg.indexOf(']', valueStart);
              if (valueEnd > valueStart) {
                // Extract and clean up the error message
                errorMsg = errorMsg.substring(valueStart, valueEnd).trim();
                // Remove extra quotes
                errorMsg = errorMsg.replaceAll('"', '');
              }
            } catch (_) {
              // If anything goes wrong during extraction, fall back to default message
              errorMsg = AppLocalizations.of(context)!.registrationError;
            }
          }
          // Try to extract 'detail' field from error message if it exists
          else if (errorMsg.contains('"detail"')) {
            try {
              // Extract content between "detail" and the closing brace
              final detailStart = errorMsg.indexOf('"detail"');
              final valueStart = errorMsg.indexOf(':', detailStart) + 1;
              final valueEnd = errorMsg.indexOf('}', valueStart);
              if (valueEnd > valueStart) {
                // Extract and clean up the detail message
                errorMsg = errorMsg.substring(valueStart, valueEnd).trim();
                // Remove extra quotes
                errorMsg = errorMsg.replaceAll('"', '');
              }
            } catch (_) {
              // If anything goes wrong during extraction, fall back to default message
              errorMsg = AppLocalizations.of(context)!.registrationError;
            }
          }
          _errorMessage = errorMsg;
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
                            // Email field
                            ResponsiveTextField(
                              controller: _emailController,
                              labelText: AppLocalizations.of(context)!.email,
                              hintText: 'example@nlenau.ro',
                              prefixIcon: Icon(Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterEmail;
                                }
                                if (!value.endsWith('@nlenau.ro')) {
                                  return AppLocalizations.of(context)!.emailMustBeNlenau;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),
                            // First name field
                            ResponsiveTextField(
                              controller: _firstNameController,
                              labelText: AppLocalizations.of(context)!.firstName,
                              prefixIcon: Icon(Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterFirstName;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),
                            // Last name field
                            ResponsiveTextField(
                              controller: _lastNameController,
                              labelText: AppLocalizations.of(context)!.lastName,
                              prefixIcon: Icon(Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterLastName;
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
                                  return AppLocalizations.of(context)!.pleaseEnterPassword;
                                }
                                if (value.length < 8) {
                                  return AppLocalizations.of(context)!.passwordMinLength;
                                }
                                if (value.contains(' ')) {
                                  return AppLocalizations.of(context)!.passwordNoSpaces;
                                }
                                if (!value.contains(RegExp(r'[A-Z]'))) {
                                  return AppLocalizations.of(context)!.passwordNeedsUppercase;
                                }
                                if (!value.contains(RegExp(r'[0-9]'))) {
                                  return AppLocalizations.of(context)!.passwordNeedsNumber;
                                }
                                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                  return AppLocalizations.of(context)!.passwordNeedsSpecialChar;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),
                            // Confirm password field
                            ResponsiveTextField(
                              controller: _confirmPasswordController,
                              labelText: AppLocalizations.of(context)!.confirmPassword,
                              prefixIcon: Icon(Icons.lock_outline),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.pleaseConfirmPassword;
                                }
                                if (value != _passwordController.text) {
                                  return AppLocalizations.of(context)!.passwordsDoNotMatch;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),
                            // Teacher switch
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(context)!.registerAsTeacher,
                                style: ResponsiveTextStyles.getResponsiveTextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: _isTeacher,
                              onChanged: (value) {
                                setState(() {
                                  _isTeacher = value;
                                  if (value) {
                                    _selectedSchoolType = null;
                                    _selectedDepartment = null;
                                    _selectedClass = null;
                                    _selectedClassCharacter = null;
                                  }
                                });
                              },
                            ),
                            if (!_isTeacher) ...[
                              SizedBox(height: getResponsiveSpacing(16.0)),
                              ResponsiveDropdownField<String>(
                                labelText: AppLocalizations.of(context)!.schoolType,
                                prefixIcon: Icon(Icons.school_outlined),
                                value: _selectedSchoolType,
                                items: _schoolTypeOptions,
                                itemToString: (type) => _getLocalizedSchoolType(context, type),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSchoolType = value;
                                    _selectedDepartment = null;
                                    _selectedClass = null;
                                    _selectedClassCharacter = null;
                                  });
                                },
                                validator: (value) {
                                  if (!_isTeacher && value == null) {
                                    return AppLocalizations.of(context)!.pleaseSelectSchoolType;
                                  }
                                  return null;
                                },
                              ),
                              if (_selectedSchoolType == 'Liceu') ...[
                                SizedBox(height: getResponsiveSpacing(16.0)),
                                ResponsiveDropdownField<String>(
                                  labelText: AppLocalizations.of(context)!.classLabel2,
                                  prefixIcon: Icon(Icons.class_outlined),
                                  value: _selectedClass,
                                  items: _liceuClassOptions,
                                  itemToString: (classOption) => classOption,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClass = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Liceu' && value == null) {
                                      return AppLocalizations.of(context)!.pleaseSelectClass;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: getResponsiveSpacing(16.0)),
                                ResponsiveDropdownField<String>(
                                  labelText: AppLocalizations.of(context)!.profile,
                                  prefixIcon: Icon(Icons.account_tree_outlined),
                                  value: _selectedDepartment,
                                  items: _departmentOptions,
                                  itemToString: (dept) => dept,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Liceu' && value == null) {
                                      return AppLocalizations.of(context)!.pleaseSelectProfile;
                                    }
                                    return null;
                                  },
                                ),
                              ] else if (_selectedSchoolType == 'Generala') ...[
                                SizedBox(height: getResponsiveSpacing(16.0)),
                                ResponsiveDropdownField<String>(
                                  labelText: AppLocalizations.of(context)!.classLabel2,
                                  prefixIcon: Icon(Icons.class_outlined),
                                  value: _selectedClass,
                                  items: _generalaClassOptions,
                                  itemToString: (classOption) => classOption,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClass = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Generala' && value == null) {
                                      return AppLocalizations.of(context)!.pleaseSelectClass;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: getResponsiveSpacing(16.0)),
                                ResponsiveDropdownField<String>(
                                  labelText: AppLocalizations.of(context)!.classLetter,
                                  prefixIcon: Icon(Icons.font_download_outlined),
                                  value: _selectedClassCharacter,
                                  items: _classCharacterOptions,
                                  itemToString: (character) => character,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClassCharacter = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Generala' && value == null) {
                                      return AppLocalizations.of(context)!.pleaseSelectClassLetter;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                            if (_isTeacher) ...[
                              SizedBox(height: getResponsiveSpacing(16.0)),
                              ResponsiveTextField(
                                controller: _invitationCodeController,
                                labelText: AppLocalizations.of(context)!.invitationCode,
                                prefixIcon: Icon(Icons.verified_user_outlined),
                                validator: (value) {
                                  if (_isTeacher && (value == null || value.isEmpty)) {
                                    return AppLocalizations.of(context)!.pleaseEnterInvitationCode;
                                  }
                                  return null;
                                },
                              ),
                            ],
                            SizedBox(height: getResponsiveSpacing(24.0)),
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
                            ResponsiveButton(
                              text: AppLocalizations.of(context)!.register,
                              onPressed: _isLoading ? null : _register,
                              isLoading: _isLoading,
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: Text(
                                AppLocalizations.of(context)!.alreadyHaveAccount,
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