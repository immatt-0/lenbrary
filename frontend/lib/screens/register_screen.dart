import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _teacherCodeController = TextEditingController();
  
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

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _teacherCodeController.dispose();
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
          teacherCode: _isTeacher && _teacherCodeController.text.isNotEmpty
              ? _teacherCodeController.text
              : null,
        );
        
        if (!mounted) return;
        
        // Show success message and return to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Înregistrare reușită! Vă rugăm să vă autentificați.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          String errorMsg = e.toString();
          // Try to extract 'detail' field from error message if it exists
          if (errorMsg.contains('"detail"')) {
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
      appBar: AppBar(
        title: const Text('Înregistrare'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    hintText: 'example@nlenau.ro',
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
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Parolă',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vă rugăm să introduceți o parolă';
                    }
                    if (value.length < 8) {
                      return 'Parola trebuie să aibă cel puțin 8 caractere';
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
                      // Reset selected values when switching
                      if (value) {
                        _selectedSchoolType = null;
                        _selectedDepartment = null;
                        _selectedClass = null;
                        _selectedClassCharacter = null;
                      }
                    });
                  },
                ),
                
                // Student-specific fields (visible only if not teacher)
                if (!_isTeacher) ...[
                  const SizedBox(height: 16.0),
                  
                  // School Type dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tip Școală',
                      border: OutlineInputBorder(),
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
                        // Reset dependent values
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
                  
                  // Show different options based on school type
                  if (_selectedSchoolType == 'Liceu') ...[
                    // Class dropdown (Liceu: IX-XII)
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Clasă',
                        border: OutlineInputBorder(),
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
                    
                    // Department dropdown (for Liceu only)
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Profil',
                        border: OutlineInputBorder(),
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
                    // Class dropdown (Generala: V-VIII)
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Clasă',
                        border: OutlineInputBorder(),
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
                    
                    // Class Character dropdown (A, B, C, etc.)
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Litera clasei',
                        border: OutlineInputBorder(),
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
                
                // Teacher code field (visible only if teacher)
                if (_isTeacher) ...[
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _teacherCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Cod profesor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isTeacher && (value == null || value.isEmpty)) {
                        return 'Vă rugăm să introduceți codul de profesor';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 24.0),
                
                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Înregistrare'),
                ),
                const SizedBox(height: 16.0),
                
                // Back to login link
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ai deja un cont? Autentifică-te'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 