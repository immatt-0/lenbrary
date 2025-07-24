import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/responsive_service.dart';

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

  Future<void> _deletePdf() async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmare ștergere'),
          content: const Text('Ești sigur că vrei să ștergi PDF-ul acestui manual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Șterge'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _pdfUrl = null;
      });

      NotificationService.showSuccess(
        context: context,
        message: 'PDF-ul a fost șters cu succes!',
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
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: ResponsiveService.isSmallPhone ? ResponsiveService.screenWidth * 0.95 : 600,
            constraints: BoxConstraints(
              maxHeight: ResponsiveService.isSmallPhone 
                  ? ResponsiveService.screenHeight * 0.85 
                  : 700,
              maxWidth: 600,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildDialogHeader(),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveService.isSmallPhone ? 16 : 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Basic Information Section
                          _buildBasicInfoSection(),
                          const SizedBox(height: 20),
                          
                          // Additional Details Section
                          _buildAdditionalDetailsSection(),
                          const SizedBox(height: 20),
                          
                          // Stock Information Section
                          _buildStockInfoSection(),
                          
                          // PDF Upload Section (only for manuals)
                          if (_selectedType == 'manual') ...[
                            const SizedBox(height: 20),
                            _buildPdfUploadSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Icon(
              Icons.edit_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editează detaliile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${widget.book['name']}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
            ),
            tooltip: 'Închide',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informații de bază',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title Field
            _buildStyledTextField(
              controller: _nameController,
              labelText: 'Numele cărții/manualului *',
              helperText: 'Titlul cărții/manualului',
              icon: Icons.book_rounded,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            
            // Author Field
            _buildStyledTextField(
              controller: _authorController,
              labelText: 'Autor *',
              helperText: 'Numele autorului',
              icon: Icons.person_rounded,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            
            // Type Selection
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tip resursă *',
                  helperText: 'Tipul cărții/manualului',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'carte', child: Text('Carte')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                ],
                onChanged: _isProcessing ? null : (value) {
                  setState(() {
                    _selectedType = value!;
                    if (_selectedType == 'carte') {
                      _selectedClass = null;
                    }
                  });
                },
              ),
            ),
            
            // Class Selection (for manuals only)
            if (_selectedType == 'manual') ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Clasă *',
                    helperText: 'Clasa pentru manual',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'V', child: Text('V - Gimnaziu')),
                    DropdownMenuItem(value: 'VI', child: Text('VI - Gimnaziu')),
                    DropdownMenuItem(value: 'VII', child: Text('VII - Gimnaziu')),
                    DropdownMenuItem(value: 'VIII', child: Text('VIII - Gimnaziu')),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Detalii suplimentare',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category Field
            _buildStyledTextField(
              controller: _categoryController,
              labelText: 'Categorie',
              helperText: 'Categoria cărții/manualului (opțional)',
              icon: Icons.category_rounded,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            
            // Description Field
            _buildStyledTextField(
              controller: _descriptionController,
              labelText: 'Descriere',
              helperText: 'Descrierea cărții (opțional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            
            // Publication Year Field
            _buildStyledTextField(
              controller: _yearController,
              labelText: 'Anul publicării',
              helperText: 'Anul publicării (opțional)',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_isProcessing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informații stoc',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock and Inventory Fields
            if (ResponsiveService.isSmallPhone) ...[
              // Stack vertically on small phones
              _buildStyledTextField(
                controller: _stockController,
                labelText: 'Stoc disponibil',
                helperText: 'Exemplare disponibile pentru împrumut',
                icon: Icons.inventory_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isProcessing,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _inventoryController,
                labelText: 'Inventar total',
                helperText: 'Numărul total de exemplare din bibliotecă',
                icon: Icons.library_books_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isProcessing,
              ),
            ] else ...[
              // Side by side on larger screens
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _stockController,
                      labelText: 'Stoc disponibil',
                      helperText: 'Exemplare disponibile',
                      icon: Icons.inventory_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_isProcessing,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _inventoryController,
                      labelText: 'Inventar total',
                      helperText: 'Total exemplare',
                      icon: Icons.library_books_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_isProcessing,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfUploadSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
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
                        'Fișier PDF (opțional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Text(
                        'Încarcă un fișier PDF pentru manual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // PDF Status and Actions
            if (_pdfUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PDF încărcat cu succes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Action Buttons
            ResponsiveService.isSmallPhone
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _uploadPdf,
                        icon: _isProcessing
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onSecondary,
                                  ),
                                ),
                              )
                            : Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(_isProcessing ? 'Se încarcă...' : 'Încarcă PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_pdfUrl != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _deletePdf,
                          icon: Icon(Icons.delete_rounded, size: 18),
                          label: const Text('Șterge PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _uploadPdf,
                          icon: _isProcessing
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onSecondary,
                                    ),
                                  ),
                                )
                              : Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(_isProcessing ? 'Se încarcă...' : 'Încarcă PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_pdfUrl != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _deletePdf,
                            icon: Icon(Icons.delete_rounded, size: 18),
                            label: const Text('Șterge PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ResponsiveService.isSmallPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Anulează'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _updateBook,
                  icon: _isProcessing
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(Icons.save_rounded, size: 18),
                  label: Text(_isProcessing ? 'Se actualizează...' : 'Salvează modificările'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('Anulează'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _updateBook,
                    icon: _isProcessing
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(Icons.save_rounded, size: 18),
                    label: Text(_isProcessing ? 'Se actualizează...' : 'Salvează modificările'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    String? helperText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          helperText: helperText,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          helperStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || author.contains(query) || category.contains(query);
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
                padding: const EdgeInsets.all(8),
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
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Administrare Cărți',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
                size: 24,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Înapoi',
            ),
          ),
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
                labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.book_rounded,
                        size: 24,
                      ),
                    ),
                    text: 'Cărți',
                  ),
                  Tab(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                          : 'Caută după titlu, autor sau categorie...',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
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
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!_isLoading && _filteredResults.isEmpty) {
      return const Center(child: Text('Nu există cărți/manuale.'));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        if (index < _filteredResults.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildBookCard(_filteredResults[index]),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildBookCard(dynamic book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            book['type'] == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          book['name'] ?? 'Carte necunoscută',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Autor: ${book['author'] ?? 'Necunoscut'}'),
            Text('Stoc: ${book['stock']}/${book['inventory']}'),
          ],
        ),
        trailing: Icon(
          Icons.edit_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          _showEditBookDialog(book);
        },
      ),
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
}
