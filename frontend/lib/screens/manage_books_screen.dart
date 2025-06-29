import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// Utility function to convert Roman numerals to Arabic numerals
int _romanToArabic(String roman) {
  final romanNumerals = {
    'I': 1,
    'V': 5,
    'X': 10,
    'L': 50,
    'C': 100,
    'D': 500,
    'M': 1000,
  };

  int result = 0;
  int prevValue = 0;

  for (int i = roman.length - 1; i >= 0; i--) {
    final currentValue = romanNumerals[roman[i]] ?? 0;
    if (currentValue >= prevValue) {
      result += currentValue;
    } else {
      result -= currentValue;
    }
    prevValue = currentValue;
  }

  return result;
}

// Utility function to convert Arabic numerals to Roman numerals
String _arabicToRoman(int arabic) {
  if (arabic <= 0) return '';
  
  final romanNumerals = [
    [1000, 'M'],
    [900, 'CM'],
    [500, 'D'],
    [400, 'CD'],
    [100, 'C'],
    [90, 'XC'],
    [50, 'L'],
    [40, 'XL'],
    [10, 'X'],
    [9, 'IX'],
    [5, 'V'],
    [4, 'IV'],
    [1, 'I'],
  ];

  String result = '';
  int remaining = arabic;

  for (final pair in romanNumerals) {
    final value = pair[0] as int;
    final numeral = pair[1] as String;
    while (remaining >= value) {
      result += numeral;
      remaining -= value;
    }
  }

  return result;
}

// A separate dialog widget for editing book details
class EditBookDialog extends StatefulWidget {
  final dynamic book;

  const EditBookDialog({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<EditBookDialog>
    with TickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _yearController;
  late final TextEditingController _stockController;
  late final TextEditingController _inventoryController;
  
  String _selectedType = 'carte';
  String? _selectedClass; // For manuals only
  bool _isProcessing = false;
  String? _pdfUrl; // For PDF upload
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.book['name'] ?? '');
    _authorController = TextEditingController(text: widget.book['author'] ?? '');
    _categoryController = TextEditingController(text: widget.book['category'] ?? '');
    _descriptionController = TextEditingController(text: widget.book['description'] ?? '');
    _yearController = TextEditingController(text: widget.book['publication_year']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.book['stock']?.toString() ?? '0');
    _inventoryController = TextEditingController(text: widget.book['inventory']?.toString() ?? '0');
    _selectedType = widget.book['type'] ?? 'carte';
    _selectedClass = widget.book['book_class'];
    _pdfUrl = widget.book['pdf_file']; // Initialize PDF URL
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _stockController.dispose();
    _inventoryController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _updateBook() async {
    if (_nameController.text.trim().isEmpty || _authorController.text.trim().isEmpty) {
      NotificationService.showError(
        context: context,
        message: 'Numele și autorul sunt obligatorii!',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedBook = await ApiService.updateBook(
        bookId: widget.book['id'],
        name: _nameController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        type: _selectedType,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        publicationYear: _yearController.text.trim().isNotEmpty ? int.tryParse(_yearController.text.trim()) : null,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        inventory: int.tryParse(_inventoryController.text.trim()) ?? 0,
        bookClass: _selectedClass,
        pdfUrl: _pdfUrl,
      );

      if (!mounted) return;

      // Return the updated book to the parent
      Navigator.of(context).pop(updatedBook);

      // Show success message
      NotificationService.showBookActionSuccess(
        context: context,
        message: 'Detaliile cărții/manualului au fost actualizate cu succes!',
      );
    } catch (e) {
      if (!mounted) return;

      // Show error and stay on dialog
      NotificationService.showError(
        context: context,
        message: 'Eroare la actualizarea cărții/manualului: ${e.toString()}',
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _uploadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _isProcessing = true;
        });
        
        try {
          String url;
          
          if (kIsWeb) {
            // For web, we need to get the bytes
            if (file.bytes != null) {
              url = await ApiService.uploadPdf(file.bytes!);
            } else {
              throw Exception('Eroare la citirea fișierului PDF');
            }
          } else {
            // For mobile, we use the file path
            if (file.path != null) {
              url = await ApiService.uploadPdf(file.path!);
            } else {
              throw Exception('Eroare la accesarea fișierului PDF');
            }
          }
          
          setState(() {
            _pdfUrl = url;
            _isProcessing = false;
          });

          NotificationService.showSuccess(
            context: context,
            message: 'PDF-ul a fost încărcat cu succes!',
          );
        } catch (e) {
          setState(() {
            _isProcessing = false;
          });
          
          NotificationService.showError(
            context: context,
            message: 'Eroare la încărcarea PDF-ului: ${e.toString()}',
          );
        }
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la selectarea fișierului PDF: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Editează "${widget.book['name']}"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: 500,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Numele cărții/manualului *',
                      helperText: 'Titlul cărții/manualului',
                      prefixIcon: Icon(
                        Icons.book_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Author field
                  TextField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      labelText: 'Autor *',
                      helperText: 'Numele autorului',
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Category field
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Categorie',
                      helperText: 'Categoria cărții/manualului (opțional)',
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Type dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Tip *',
                        helperText: 'Tipul cărții/manualului',
                        prefixIcon: Icon(
                          Icons.type_specimen_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'carte', child: Text('Carte')),
                        DropdownMenuItem(value: 'manual', child: Text('Manual')),
                      ],
                      onChanged: _isProcessing ? null : (value) {
                        setState(() {
                          _selectedType = value!;
                          // Reset class when type changes
                          if (_selectedType == 'carte') {
                            _selectedClass = null;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Class dropdown (only for manuals)
                  if (_selectedType == 'manual') ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Clasă *',
                          helperText: 'Clasa pentru manual',
                          prefixIcon: Icon(
                            Icons.school_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          // Gimnaziu classes
                          DropdownMenuItem(value: 'V', child: Text('V - Gimnaziu')),
                          DropdownMenuItem(value: 'VI', child: Text('VI - Gimnaziu')),
                          DropdownMenuItem(value: 'VII', child: Text('VII - Gimnaziu')),
                          DropdownMenuItem(value: 'VIII', child: Text('VIII - Gimnaziu')),
                          // Liceu classes
                          DropdownMenuItem(value: 'IX', child: Text('IX - Liceu')),
                          DropdownMenuItem(value: 'X', child: Text('X - Liceu')),
                          DropdownMenuItem(value: 'XI', child: Text('XI - Liceu')),
                          DropdownMenuItem(value: 'XII', child: Text('XII - Liceu')),
                        ],
                        onChanged: _isProcessing ? null : (value) {
                          setState(() {
                            _selectedClass = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Description field
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descriere',
                      helperText: 'Descrierea cărții (opțional)',
                      prefixIcon: Icon(
                        Icons.description_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Publication year field
                  TextField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: 'Anul publicării',
                      helperText: 'Anul publicării (opțional)',
                      prefixIcon: Icon(
                        Icons.calendar_today_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_isProcessing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Stock and inventory fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stockController,
                          decoration: InputDecoration(
                            labelText: 'Stoc disponibil',
                            helperText: 'Exemplare disponibile',
                            prefixIcon: Icon(
                              Icons.inventory_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          enabled: !_isProcessing,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _inventoryController,
                          decoration: InputDecoration(
                            labelText: 'Inventar total',
                            helperText: 'Total exemplare',
                            prefixIcon: Icon(
                              Icons.library_books_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          enabled: !_isProcessing,
                        ),
                      ),
                    ],
                  ),
                  
                  // PDF upload field (only for manuals)
                  if (_selectedType == 'manual') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fișier PDF',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Încarcă un fișier PDF pentru manual',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_pdfUrl != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'PDF încărcat',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _uploadPdf,
                            icon: _isProcessing
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                    ),
                                  )
                                : Icon(Icons.upload_file_rounded),
                            label: Text(_isProcessing ? 'Se încarcă...' : 'Selectează PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _isProcessing ? null : _cancel,
              icon: Icon(Icons.cancel_rounded),
              label: const Text('Anulează'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _updateBook,
              icon: _isProcessing
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Icon(Icons.save_rounded),
              label: Text(_isProcessing ? 'Se actualizează...' : 'Salvează'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A separate dialog widget that handles its own state management
class UpdateBookDialog extends StatefulWidget {
  final dynamic book;

  const UpdateBookDialog({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<UpdateBookDialog> createState() => _UpdateBookDialogState();
}

class _UpdateBookDialogState extends State<UpdateBookDialog>
    with TickerProviderStateMixin {
  late final TextEditingController _stockController;
  late final TextEditingController _inventoryController;
  bool _isProcessing = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _stockController =
        TextEditingController(text: widget.book['stock'].toString());
    _inventoryController =
        TextEditingController(text: widget.book['inventory'].toString());
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _stockController.dispose();
    _inventoryController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _updateStock() async {
    final newStock = int.tryParse(_stockController.text) ?? 0;
    final newInventory = int.tryParse(_inventoryController.text) ?? 0;

    setState(() {
      _isProcessing = true;
    });

    try {
      final updatedBook = await ApiService.updateBookStock(
        bookId: widget.book['id'],
        stock: newStock,
        inventory: newInventory,
      );

      if (!mounted) return;

      // Return the updated book to the parent
      Navigator.of(context).pop(updatedBook);

      // Show success message
      NotificationService.showBookActionSuccess(
        context: context,
        message: 'Stocul cărții/manualului a fost actualizat cu succes!',
      );
    } catch (e) {
      if (!mounted) return;

      // Show error and stay on dialog
      NotificationService.showError(
        context: context,
        message: 'Eroare la actualizarea cărții/manualului: ${e.toString()}',
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Actualizare "${widget.book['name']}"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: 400,
            child: Column(
        mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
        children: [
          TextField(
            controller: _stockController,
                        decoration: InputDecoration(
              labelText: 'Stoc disponibil',
              helperText: 'Numărul de exemplare disponibile pentru împrumut',
                          prefixIcon: Icon(
                            Icons.inventory_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isProcessing,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inventoryController,
                        decoration: InputDecoration(
              labelText: 'Inventar total',
              helperText: 'Numărul total de exemplare din bibliotecă',
                          prefixIcon: Icon(
                            Icons.library_books_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isProcessing,
          ),
        ],
                  ),
                ),
              ],
            ),
      ),
      actions: [
            TextButton.icon(
          onPressed: _isProcessing ? null : _cancel,
              icon: Icon(Icons.cancel_rounded),
              label: const Text('Anulează'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            ElevatedButton.icon(
          onPressed: _isProcessing ? null : _updateStock,
              icon: _isProcessing
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Icon(Icons.save_rounded),
              label: Text(_isProcessing ? 'Se actualizează...' : 'Actualizează'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({Key? key}) : super(key: key);

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _books = [];
  List<dynamic> _filteredBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _processingAction = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  Timer? _debounceTimer;

  // Search controller
  late TextEditingController _searchController;

  // Keep track of mounted state through async operations
  bool _isMounted = true;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController = TextEditingController();
    _loadBooks();
    
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
    _isMounted = false;
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _tabController.index == 0 ? 'carti' : 'manuale';
        _isLoading = true; // Show loading when switching tabs
      });
      _loadBooks();
    }
  }

  void _filterBooks([String? query]) {
    final searchQuery = query ?? _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = searchQuery;
      if (searchQuery.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books.where((book) {
          // First, ensure the book belongs to the current category
          final bookType = book['type']?.toLowerCase() ?? '';
          final currentCategory = _selectedCategory.toLowerCase();
          
          // If we're in "carti" tab, only show books with type "carte"
          if (currentCategory == 'carti' && bookType != 'carte') {
            return false;
          }
          
          // If we're in "manuale" tab, only show books with type "manual"
          if (currentCategory == 'manuale' && bookType != 'manual') {
            return false;
          }
          
          final name = book['name']?.toLowerCase() ?? '';
          final author = book['author']?.toLowerCase() ?? '';
          final category = book['category']?.toLowerCase() ?? '';
          final bookClass = book['book_class']?.toString().toLowerCase() ?? '';
          
          // Check if search query matches name, author, or category
          if (name.contains(searchQuery) || 
              author.contains(searchQuery) || 
              category.contains(searchQuery)) {
            return true;
          }
          
          // Check if search query matches book class (Roman or Arabic numerals)
          // Only for manuals (when in manuale tab)
          if (currentCategory == 'manuale' && bookClass.isNotEmpty && searchQuery.isNotEmpty) {
            // Direct match
            if (bookClass.contains(searchQuery)) {
              return true;
            }
            
            // Try to convert search query to Roman numeral if it's a number
            if (RegExp(r'^\d+$').hasMatch(searchQuery)) {
              final arabicNum = int.tryParse(searchQuery);
              if (arabicNum != null) {
                final romanNum = _arabicToRoman(arabicNum).toLowerCase();
                if (bookClass.contains(romanNum)) {
                  return true;
                }
              }
            }
            
            // Try to convert search query to Arabic numeral if it looks like Roman numerals
            if (RegExp(r'^[IVXLCDM]+$', caseSensitive: false).hasMatch(searchQuery.toUpperCase())) {
              final arabicNum = _romanToArabic(searchQuery.toUpperCase());
              if (arabicNum > 0) {
                final arabicStr = arabicNum.toString();
                if (bookClass.contains(arabicStr)) {
                  return true;
                }
              }
            }
          }
          
          return false;
        }).toList();
      }
    });
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Only do local filtering, no API calls during search
    _filterBooks();
  }

  void _updateState(VoidCallback action) {
    // Only update state if the widget is still mounted
    if (_isMounted && mounted) {
      setState(action);
    }
  }

  Future<void> _loadBooks() async {
    // Only show loading for initial load and tab changes
    if (_books.isEmpty || _isLoading) {
      _updateState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final books = await ApiService.getBooks(
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
      );

      // Check mounted again after async operation
      if (!_isMounted || !mounted) return;

      _updateState(() {
        _books = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      // Check mounted again after async operation
      if (!_isMounted || !mounted) return;

      _updateState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showUpdateDialog(dynamic book) async {
    if (!_isMounted || !mounted) return;

    // Show a separate stateful dialog widget
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateBookDialog(book: book),
    );

    // Update the book in our local list if we got a result back
    if (result != null && mounted) {
      _updateState(() {
        for (int i = 0; i < _books.length; i++) {
          if (_books[i]['id'] == result['id']) {
            _books[i] = result;
            break;
          }
        }
      });

      // Show success message
      NotificationService.showBookActionSuccess(
        context: context,
        message: 'Stocul cărții/manualului a fost actualizat cu succes!',
      );
    }
  }

  Future<void> _showEditDialog(dynamic book) async {
    if (!_isMounted || !mounted) return;

    // Show a separate stateful dialog widget
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditBookDialog(book: book),
    );

    // Update the book in our local list if we got a result back
    if (result != null && mounted) {
      _updateState(() {
        for (int i = 0; i < _books.length; i++) {
          if (_books[i]['id'] == result['id']) {
            _books[i] = result;
            break;
          }
        }
      });

      // Show success message
      NotificationService.showBookActionSuccess(
        context: context,
        message: 'Detaliile cărții/manualului au fost actualizate cu succes!',
      );
    }
  }

  Future<void> _showDeleteDialog(dynamic book) async {
    if (!_isMounted || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Șterge carte/manual',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ești sigur că vrei să ștergi cartea/manualul "${book['name']}"?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Atenție!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Această acțiune nu poate fi anulată. Cartea/manualul va fi ștearsă definitiv din catalog.',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Anulează',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Șterge',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteBook(book);
    }
  }

  Future<void> _deleteBook(dynamic book) async {
    _updateState(() {
      _processingAction = true;
    });

    try {
      await ApiService.deleteBook(bookId: book['id']);
      
      // Remove the book from the local list
      _updateState(() {
        _books.removeWhere((b) => b['id'] == book['id']);
        _filteredBooks.removeWhere((b) => b['id'] == book['id']);
      });

      // Show success message
      NotificationService.showSuccess(
        context: context,
        message: 'Cartea/manualul "${book['name']}" a fost ștearsă cu succes!',
      );
    } catch (e) {
      // Show error message
      NotificationService.showError(
        context: context,
        message: 'Eroare la ștergerea cărții/manualului: ${e.toString()}',
      );
    } finally {
      _updateState(() {
        _processingAction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: true,
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Gestionare Cărți și Manuale',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
            onPressed: _loadBooks,
                tooltip: 'Reîmprospătează',
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
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
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.book_rounded,
                      size: 24,
                    ),
                  ),
                  text: 'Cărți',
                ),
                Tab(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 24,
                    ),
                  ),
                  text: 'Manuale',
                ),
              ],
            ),
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
        child: Column(
          children: [
            // Search Bar - Always visible
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Caută după titlu, autor, categorie sau clasă...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            _debounceTimer?.cancel();
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _filteredBooks = _books;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Search Results Count
            if (_searchQuery.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredBooks.length} rezultat${_filteredBooks.length == 1 ? '' : 'e'} găsit${_filteredBooks.length == 1 ? '' : 'e'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
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
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Se încarcă cărțile și manualele...',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: ElevatedButton.icon(
                                  onPressed: _loadBooks,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Reîncearcă'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredBooks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 800),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.library_books_rounded,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Nu s-au găsit rezultate pentru "${_searchQuery}"'
                                          : 'Nu există cărți sau manuale în această categorie',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  itemCount: _filteredBooks.length,
                                  itemBuilder: (context, index) {
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 400 + (index * 100)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: _buildBookCard(_filteredBooks[index]),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
            child: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-book').then((_) {
            if (_isMounted && mounted) {
              _loadBooks();
            }
          });
        },
        tooltip: 'Adaugă carte',
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(dynamic book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book information with photo first
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover image on the left
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: book['thumbnail_url'] != null && book['thumbnail_url'].isNotEmpty
                          ? Image.network(
                      book['thumbnail_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[200]!,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[200]!,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book title and author
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.book_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['name'] ?? 'Carte necunoscută',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                      Text(
                                        book['author'] ?? '',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Category
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categorie',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                      Text(
                                    book['category'] ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Class (only for manuals)
                      if (book['type'] == 'manual' && book['book_class'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clasă',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      book['book_class'] ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Stock information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.tertiary.withOpacity(0.15),
                                    Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_rounded,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                      Text(
                                    'Stoc',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                      Text(
                                    '${book['stock'] ?? 0} exemplare',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Delete button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.red.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _processingAction
                          ? null
                          : () => _showDeleteDialog(book),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Șterge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _processingAction
                          ? null
                          : () => _showEditDialog(book),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editează'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock management button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
                    child: ElevatedButton.icon(
                      onPressed: _processingAction
                          ? null
                          : () => _showUpdateDialog(book),
                      icon: const Icon(Icons.inventory_rounded),
                      label: const Text('Gestionare stoc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
