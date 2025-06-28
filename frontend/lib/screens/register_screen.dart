import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
            message: 'Înregistrare reușită! Verifică inboxul pentru a-ți activa contul.',
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
              errorMsg = "Eroare la înregistrare. Vă rugăm să încercați din nou.";
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
              errorMsg = "Eroare la înregistrare. Vă rugăm să încercați din nou.";
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
    return Scaffold(
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
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16.0),
                            // App title
                            const Text(
                              'Lenbrary',
                              style: TextStyle(
                                fontSize: 32.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32.0),
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'example@nlenau.ro',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vă rugăm să introduceți o adresă de email';
                                }
                                if (!value.endsWith('@nlenau.ro')) {
                                  return 'Email-ul trebuie să fie din domeniul nlenau.ro';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // First name field
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'Prenume',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vă rugăm să introduceți prenumele';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Last name field
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nume',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vă rugăm să introduceți numele';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Parolă',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vă rugăm să introduceți o parolă';
                                }
                                if (value.length < 8) {
                                  return 'Parola trebuie să aibă cel puțin 8 caractere';
                                }
                                if (value.contains(' ')) {
                                  return 'Parola nu poate conține spații';
                                }
                                if (!value.contains(RegExp(r'[A-Z]'))) {
                                  return 'Parola trebuie să conțină cel puțin o literă mare';
                                }
                                if (!value.contains(RegExp(r'[0-9]'))) {
                                  return 'Parola trebuie să conțină cel puțin o cifră';
                                }
                                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                  return 'Parola trebuie să conțină cel puțin un caracter special';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Confirm password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirmă parola',
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vă rugăm să confirmați parola';
                                }
                                if (value != _passwordController.text) {
                                  return 'Parolele nu se potrivesc';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Teacher switch
                            SwitchListTile(
                              title: const Text('Înregistrare ca profesor'),
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
                              const SizedBox(height: 16.0),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Tip Școală',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                value: _selectedSchoolType,
                                items: _schoolTypeOptions.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
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
                                    return 'Vă rugăm să selectați tipul de școală';
                                  }
                                  return null;
                                },
                              ),
                              if (_selectedSchoolType == 'Liceu') ...[
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Clasă',
                                    prefixIcon: Icon(Icons.class_outlined),
                                  ),
                                  value: _selectedClass,
                                  items: _liceuClassOptions.map((classOption) {
                                    return DropdownMenuItem<String>(
                                      value: classOption,
                                      child: Text(classOption),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClass = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Liceu' && value == null) {
                                      return 'Vă rugăm să selectați clasa';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Profil',
                                    prefixIcon: Icon(Icons.account_tree_outlined),
                                  ),
                                  value: _selectedDepartment,
                                  items: _departmentOptions.map((dept) {
                                    return DropdownMenuItem<String>(
                                      value: dept,
                                      child: Text(dept),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Liceu' && value == null) {
                                      return 'Vă rugăm să selectați profilul';
                                    }
                                    return null;
                                  },
                                ),
                              ] else if (_selectedSchoolType == 'Generala') ...[
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Clasă',
                                    prefixIcon: Icon(Icons.class_outlined),
                                  ),
                                  value: _selectedClass,
                                  items: _generalaClassOptions.map((classOption) {
                                    return DropdownMenuItem<String>(
                                      value: classOption,
                                      child: Text(classOption),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClass = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Generala' && value == null) {
                                      return 'Vă rugăm să selectați clasa';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Litera clasei',
                                    prefixIcon: Icon(Icons.font_download_outlined),
                                  ),
                                  value: _selectedClassCharacter,
                                  items: _classCharacterOptions.map((character) {
                                    return DropdownMenuItem<String>(
                                      value: character,
                                      child: Text(character),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClassCharacter = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedSchoolType == 'Generala' && value == null) {
                                      return 'Vă rugăm să selectați litera clasei';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                            if (_isTeacher) ...[
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _invitationCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Cod de invitație',
                                  prefixIcon: Icon(Icons.verified_user_outlined),
                                ),
                                validator: (value) {
                                  if (_isTeacher && (value == null || value.isEmpty)) {
                                    return 'Vă rugăm să introduceți codul de invitație';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 24.0),
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_errorMessage != null)
                              const SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20.0,
                                        width: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Înregistrare',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Ai deja un cont? Autentifică-te'),
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