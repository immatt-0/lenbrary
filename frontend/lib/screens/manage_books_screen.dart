import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_book_card.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';

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

      // Verify the update by fetching the book details again
      final allBooks = await ApiService.getBooks();
      final verifiedBook = allBooks.firstWhere((b) => b['id'] == widget.book['id'], orElse: () => null);
      bool verified = false;
      if (verifiedBook != null) {
        verified =
          (verifiedBook['name'] ?? '') == _nameController.text.trim() &&
          (verifiedBook['author'] ?? '') == _authorController.text.trim() &&
          (verifiedBook['category'] ?? '') == _categoryController.text.trim() &&
          (verifiedBook['type'] ?? '') == _selectedType &&
          (verifiedBook['description'] ?? '') == _descriptionController.text.trim() &&
          (verifiedBook['publication_year']?.toString() ?? '') == _yearController.text.trim() &&
          (verifiedBook['stock']?.toString() ?? '0') == (_stockController.text.trim().isEmpty ? '0' : _stockController.text.trim()) &&
          (verifiedBook['inventory']?.toString() ?? '0') == (_inventoryController.text.trim().isEmpty ? '0' : _inventoryController.text.trim()) &&
          (verifiedBook['book_class'] ?? '') == (_selectedClass ?? '') &&
          (verifiedBook['pdf_file'] ?? '') == (_pdfUrl ?? '');
      }

      if (!mounted) return;

      if (verified) {
        NotificationService.showBookActionSuccess(
          context: context,
          message: 'Detaliile cărții/manualului au fost actualizate și verificate cu succes!',
        );
      } else {
        NotificationService.showError(
          context: context,
          message: 'Actualizarea a fost trimisă, dar verificarea a eșuat. Vă rugăm să reîncercați sau să verificați manual.',
        );
      }

      Navigator.of(context).pop(updatedBook);
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
    ResponsiveService.init(context);
    
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
    with TickerProviderStateMixin, ResponsiveWidget {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _allBooks = [];
  List<dynamic> _filteredResults = [];
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _selectedCategory = 'carte';
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _tabController.index == 0 ? 'carte' : 'manual';
        _isLoading = true;
        _searchQuery = '';
      });
      _searchController.clear();
      _filterBooks();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBooks() {
    List<dynamic> filtered = _allBooks;
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((book) => (book['type'] ?? 'carte') == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) {
        final title = (book['name'] ?? '').toString().toLowerCase();
        final author = (book['author'] ?? '').toString().toLowerCase();
        final category = (book['category'] ?? '').toString().toLowerCase();
        final bookClass = (book['book_class'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (title.contains(query) || author.contains(query) || category.contains(query)) {
          return true;
        }
        if (book['type'] == 'manual' && bookClass.isNotEmpty) {
          final arabicClass = _romanToArabic(bookClass.toUpperCase()).toString();
          if (bookClass.contains(query) || arabicClass.contains(query)) {
            return true;
          }
        }
        return false;
      }).toList();
    }
    setState(() {
      _filteredResults = filtered;
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await ApiService.getBooks();
      setState(() {
        _allBooks = books;
        _isLoading = false;
      });
      _filterBooks();
    } catch (e) {
      setState(() {
        _allBooks = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _filterBooks();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = value;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _filterBooks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(getResponsiveSpacing(8)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: getResponsiveBorderRadius(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: getResponsiveSpacing(8),
                      offset: Offset(0, getResponsiveSpacing(2)),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                'Administrare Cărți',
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          leading: Container(
            margin: EdgeInsets.only(left: getResponsiveSpacing(8)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: getResponsiveBorderRadius(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: getResponsiveIconSize(24),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Înapoi',
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(getResponsiveSpacing(120)),
            child: Container(
              margin: getResponsivePadding(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
                borderRadius: getResponsiveBorderRadius(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    blurRadius: getResponsiveSpacing(16),
                    offset: Offset(0, getResponsiveSpacing(6)),
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
                  borderRadius: getResponsiveBorderRadius(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: getResponsiveSpacing(8),
                      offset: Offset(0, getResponsiveSpacing(2)),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      child: Icon(
                        Icons.book_rounded,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                    text: 'Cărți',
                  ),
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: getResponsiveIconSize(24),
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
              Padding(
                padding: getResponsivePadding(all: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: getResponsiveBorderRadius(25),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: getResponsiveSpacing(12),
                        offset: Offset(0, getResponsiveSpacing(4)),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: ResponsiveService.isSmallPhone 
                          ? 'Caută cărți și manuale...'
                          : 'Caută după titlu, autor, categorie sau clasă (ex: VIII sau 8)...',
                      hintStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      ),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(getResponsiveSpacing(8)),
                        padding: EdgeInsets.all(getResponsiveSpacing(10)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: getResponsiveBorderRadius(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: getResponsiveIconSize(24),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                margin: EdgeInsets.all(getResponsiveSpacing(8)),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: getResponsiveBorderRadius(10),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: getResponsiveIconSize(20),
                                  ),
                                  onPressed: () {
                                    _debounceTimer?.cancel();
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _filterBooks();
                                  },
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: getResponsiveSpacing(20),
                        vertical: getResponsiveSpacing(16),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      setState(() {
                        _searchQuery = value;
                      });
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _filterBooks();
                        }
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Cărți Tab
                    _buildTabContent('carte'),
                    // Manuale Tab
                    _buildTabContent('manual'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String category) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!_isLoading && _filteredResults.isEmpty) {
      return Center(child: Text('Nu există cărți/manuale.'));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveSpacing(12),
        vertical: getResponsiveSpacing(8),
      ),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        if (index < _filteredResults.length) {
          return _buildBookCard(_filteredResults[index]);
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildBookCard(dynamic book) {
    return ResponsiveBookCard(
      title: book['name'] ?? 'Carte necunoscută',
      author: book['author'] ?? 'Autor necunoscut',
      category: book['category'] ?? 'Necategorizat',
      bookType: book['type'] ?? 'Carte',
      bookClass: book['book_class'],
      thumbnailUrl: getFullThumbnailUrl(book['thumbnail_url']),
      availableCopies: book['stock'],
      totalCopies: book['inventory'],
      showActions: false,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EditBookScreen(book: book),
        ));
      },
    );
  }

  Future<void> _showEditBookDialog(dynamic book) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditBookDialog(book: book),
    );
    if (result != null) {
      _loadBooks();
    }
  }

  // Helper to show AddBookScreen as a dialog
  Future<void> _showAddBookDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: ResponsiveService.dialogWidth,
          height: ResponsiveService.dialogHeight,
          child: AddBookScreen(),
        ),
      ),
    );
    if (result != null) {
      _loadBooks();
    }
  }

  // Helper to build a full thumbnail URL
  String? getFullThumbnailUrl(String? thumbnailUrl) {
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return null;
    if (thumbnailUrl.startsWith('http')) return thumbnailUrl;
    String cleanPath = thumbnailUrl.replaceFirst(RegExp(r'^/+'), '');
    return '${ApiService.baseUrl}/media/$cleanPath';
  }

  // Helper to build a full PDF URL
  String? getFullPdfUrl(String? pdfUrl) {
    if (pdfUrl == null || pdfUrl.isEmpty) return null;
    if (pdfUrl.startsWith('http')) return pdfUrl;
    String cleanPath = pdfUrl.replaceFirst(RegExp(r'^(\/)?(media\/)+'), '');
    return '${ApiService.baseUrl}/media/$cleanPath';
  }
}
