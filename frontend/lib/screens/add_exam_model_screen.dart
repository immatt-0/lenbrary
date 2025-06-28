import 'package:flutter/material.dart';
import 'exam_models_admin_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddExamModelScreen extends StatefulWidget {
  const AddExamModelScreen({Key? key}) : super(key: key);

  @override
  State<AddExamModelScreen> createState() => _AddExamModelScreenState();
}

class _AddExamModelScreenState extends State<AddExamModelScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _examName;
  String? _examType; // 'EN' or 'BAC'
  String? _category; // 'Matematica' or 'Romana'
  String? _pdfFileName;
  String? _pdfFilePath;
  Uint8List? _pdfFileBytes;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // get bytes for web
    );
    if (result != null) {
      setState(() {
        _pdfFileName = result.files.single.name;
        if (kIsWeb) {
          _pdfFileBytes = result.files.single.bytes;
          _pdfFilePath = null;
        } else {
          _pdfFilePath = result.files.single.path;
          _pdfFileBytes = null;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        (_pdfFilePath != null || _pdfFileBytes != null) &&
        _examType != null &&
        _category != null) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.addExamModel(
          name: _examName!,
          type: _examType!,
          category: _category!,
          pdfFilePath: _pdfFilePath,
          pdfFileBytes: _pdfFileBytes,
          pdfFileName: _pdfFileName,
        );
        print('Add exam model result: ' + result.toString());
        setState(() => _isLoading = false);
        Navigator.pop(context, result);
      } catch (e) {
        setState(() => _isLoading = false);
        print('Error adding exam model: ' + e.toString());
        NotificationService.showError(
          context: context,
          message: 'Eroare la adăugare: $e',
        );
      }
    } else if (_pdfFilePath == null && _pdfFileBytes == null) {
      NotificationService.showFileUploadError(
        context: context,
        message: 'Vă rugăm să selectați un fișier PDF.',
      );
    } else if (_examType == null) {
      NotificationService.showValidationError(
        context: context,
        message: 'Vă rugăm să selectați tipul examenului.',
      );
    } else if (_category == null) {
      NotificationService.showValidationError(
        context: context,
        message: 'Vă rugăm să selectați materia.',
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'EN':
        return const Color(0xFF10B981); // Green
      case 'BAC':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Matematica':
        return const Color(0xFF3B82F6); // Blue
      case 'Romana':
        return const Color(0xFFEF4444); // Red
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_task_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Adaugă Model de Examen',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Înapoi',
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.secondary.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 500,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.add_task_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Model de Examen Nou',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Completează detaliile modelului de examen',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Form Fields
                            _buildFormField(
                              label: 'Nume model examen',
                              icon: Icons.title_rounded,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Introduceți un nume'
                                  : null,
                              onSaved: (value) => _examName = value,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown(
                              label: 'Tip examen',
                              icon: Icons.school_rounded,
                              value: _examType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'EN', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 20),
                                      SizedBox(width: 8),
                                      Text('Evaluare Națională (EN)'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'BAC', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 20),
                                      SizedBox(width: 8),
                                      Text('Bacalaureat (BAC)'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => _examType = value),
                              validator: (value) =>
                                  value == null ? 'Selectați tipul examenului' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown(
                              label: 'Materia',
                              icon: Icons.book_rounded,
                              value: _category,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Matematica', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.functions_rounded, color: Color(0xFF3B82F6), size: 20),
                                      SizedBox(width: 8),
                                      Text('Matematică'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Romana', 
                                  child: Row(
                                    children: [
                                      Icon(Icons.menu_book_rounded, color: Color(0xFFEF4444), size: 20),
                                      SizedBox(width: 8),
                                      Text('Română'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => _category = value),
                              validator: (value) =>
                                  value == null ? 'Selectați materia' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildFilePicker(),
                            const SizedBox(height: 32),

                            // Submit Button
                            _isLoading
                                ? Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _submit,
                                      icon: const Icon(Icons.save_rounded, size: 24),
                                      label: const Text(
                                        'Adaugă modelul',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
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

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required Function(String?) onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
        onSaved: onSaved,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: _pickPdf,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pdfFileName == null ? 'Alege fișier PDF' : _pdfFileName!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _pdfFileName == null 
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) 
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_pdfFileName == null)
                      Text(
                        'Apasă pentru a selecta un fișier PDF',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.upload_file_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
