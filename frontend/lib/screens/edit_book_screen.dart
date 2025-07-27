import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class EditBookScreen extends StatefulWidget {
  final dynamic book;
  const EditBookScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen>
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
  String? _thumbnailUrl; // For thumbnail upload
  String? _pdfUrl; // For PDF upload
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _nameController = TextEditingController(text: book['name'] ?? '');
    _authorController = TextEditingController(text: book['author'] ?? '');
    _categoryController = TextEditingController(text: book['category'] ?? '');
    _descriptionController = TextEditingController(text: book['description'] ?? '');
    _yearController = TextEditingController(text: book['publication_year']?.toString() ?? '');
    _stockController = TextEditingController(text: book['stock']?.toString() ?? '0');
    _inventoryController = TextEditingController(text: book['inventory']?.toString() ?? '0');
    _selectedType = book['type'] ?? 'carte';
    _selectedClass = book['book_class'];
    _thumbnailUrl = book['thumbnail_url']; // Initialize thumbnail URL
    _pdfUrl = book['pdf_file']; // Initialize PDF URL
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: 0.9,
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
      print('=== UPDATE BOOK DEBUG ===');
      print('Book ID: ${widget.book['id']}');
      print('PDF URL to send: $_pdfUrl');
      print('Thumbnail URL to send: $_thumbnailUrl');
      
      // Convert full URLs to relative paths for backend
      String? pdfToSend = _pdfUrl;
      if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
        pdfToSend = ApiService.extractRelativeMediaPath(_pdfUrl!);
        print('Converted PDF path: $pdfToSend');
      }
      
      String? thumbnailToSend = _thumbnailUrl;
      if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty) {
        thumbnailToSend = ApiService.extractRelativeMediaPath(_thumbnailUrl!);
        print('Converted thumbnail path: $thumbnailToSend');
      }
      print('========================');
      
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
        pdfUrl: pdfToSend,
        thumbnailUrl: thumbnailToSend,
      );

      print('=== UPDATE RESPONSE ===');
      print('Updated book: $updatedBook');
      print('=====================');

      if (!mounted) return;

      NotificationService.showBookActionSuccess(
        context: context,
        message: 'Detaliile cărții/manualului au fost actualizate cu succes!',
      );

      Navigator.of(context).pop(updatedBook);
    } catch (e) {
      if (!mounted) return;

      NotificationService.showError(
        context: context,
        message: 'Eroare la actualizarea cărții/manualului: ${e.toString()}',
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _uploadThumbnail() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
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
            if (file.bytes != null) {
              url = await ApiService.uploadThumbnail(file.bytes!);
            } else {
              throw Exception('Nu s-a putut accesa fișierul selectat');
            }
          } else {
            if (file.path != null) {
              url = await ApiService.uploadThumbnail(file.path!);
            } else {
              throw Exception('Nu s-a putut accesa calea fișierului');
            }
          }
          
          setState(() {
            _thumbnailUrl = url;
            _isProcessing = false;
          });

          NotificationService.showSuccess(
            context: context,
            message: 'Imaginea a fost încărcată cu succes!',
          );
        } catch (e) {
          setState(() {
            _isProcessing = false;
          });
          
          NotificationService.showError(
            context: context,
            message: 'Eroare la încărcarea imaginii: ${e.toString()}',
          );
        }
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la selectarea imaginii: ${e.toString()}',
      );
    }
  }

  Future<void> _deleteThumbnail() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmare ștergere'),
          content: const Text('Ești sigur că vrei să ștergi imaginea acestei cărți?'),
          actions: [
            TextButton(
              child: const Text('Anulează'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Șterge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // If there's a thumbnail URL, we need to delete it from the server by updating the book
        if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty) {
          await ApiService.updateBook(
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
            pdfUrl: _pdfUrl != null && _pdfUrl!.isNotEmpty ? ApiService.extractRelativeMediaPath(_pdfUrl!) : null,
            thumbnailUrl: '', // Send empty string to delete the thumbnail
          );
        }

        setState(() {
          _thumbnailUrl = null;
          _isProcessing = false;
        });

        NotificationService.showSuccess(
          context: context,
          message: 'Imaginea a fost ștearsă cu succes!',
        );
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });

        NotificationService.showError(
          context: context,
          message: 'Eroare la ștergerea imaginii: ${e.toString()}',
        );
      }
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
            if (file.bytes != null) {
              url = await ApiService.uploadPdf(file.bytes!);
            } else {
              throw Exception('Nu s-a putut accesa fișierul selectat');
            }
          } else {
            if (file.path != null) {
              url = await ApiService.uploadPdf(file.path!);
            } else {
              throw Exception('Nu s-a putut accesa calea fișierului');
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
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmare ștergere'),
          content: const Text('Ești sigur că vrei să ștergi PDF-ul acestui manual?'),
          actions: [
            TextButton(
              child: const Text('Anulează'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Șterge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // If there's a PDF URL, we need to delete it from the server by updating the book
        if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
          await ApiService.updateBook(
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
            pdfUrl: '', // Send empty string to delete the PDF
          );
        }

        setState(() {
          _pdfUrl = null;
          _isProcessing = false;
        });

        NotificationService.showSuccess(
          context: context,
          message: 'PDF-ul a fost șters cu succes!',
        );
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });

        NotificationService.showError(
          context: context,
          message: 'Eroare la ștergerea PDF-ului: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: EdgeInsets.only(left: ResponsiveService.isSmallPhone ? 6 : 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 6 : 8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveService.isSmallPhone ? 18 : 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Înapoi',
          ),
        ),
        centerTitle: true,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: ResponsiveService.isSmallPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
              Flexible(
                child: Text(
                  ResponsiveService.isSmallPhone ? 'Editează' : 'Editează Carte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: ResponsiveService.isSmallPhone ? 18 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail Section
                  _buildThumbnailSection(),
                  SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                  
                  // Basic Info Section
                  _buildBasicInfoSection(),
                  SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                  
                  // Additional Details Section
                  _buildAdditionalDetailsSection(),
                  SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                  
                  // Stock Info Section
                  _buildStockInfoSection(),
                  
                  // PDF Upload Section (for manuals only)
                  if (_selectedType == 'manual') ...[
                    SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                    _buildPdfUploadSection(),
                  ],
                  
                  SizedBox(height: ResponsiveService.isSmallPhone ? 24 : 32),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    final String? thumbnailUrl = _thumbnailUrl != null
        ? (_thumbnailUrl!.startsWith('http')
            ? _thumbnailUrl
            : ApiService.baseUrl + '/media/' + _thumbnailUrl!.replaceAll(RegExp(r'^/?media/'), ''))
        : null;

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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: ResponsiveService.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagine copertă',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                        ),
                      ),
                      SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                      Text(
                        'Imaginea care va fi afișată ca copertă',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: ResponsiveService.isSmallPhone ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
            
            // Thumbnail Preview and Actions
            Center(
              child: Column(
                children: [
                  // Thumbnail Preview
                  Container(
                    width: ResponsiveService.isSmallPhone ? 100 : 120,
                    height: ResponsiveService.isSmallPhone ? 140 : 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                          offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 12 : 16),
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    _selectedType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                    size: ResponsiveService.isSmallPhone ? 48 : 56,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                              child: Icon(
                                _selectedType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                size: ResponsiveService.isSmallPhone ? 48 : 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                  
                  // Action Buttons
                  ResponsiveService.isSmallPhone
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _uploadThumbnail,
                                icon: Icon(Icons.upload_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                                label: Text(
                                  'Încarcă imagine',
                                  style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                                    vertical: ResponsiveService.isSmallPhone ? 10 : 12,
                                  ),
                                ),
                              ),
                            ),
                            if (_thumbnailUrl != null) ...[
                              SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : _deleteThumbnail,
                                  icon: Icon(Icons.delete_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                                  label: Text(
                                    'Șterge',
                                    style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                                      vertical: ResponsiveService.isSmallPhone ? 10 : 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _uploadThumbnail,
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Încarcă imagine'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                            if (_thumbnailUrl != null) ...[
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: _isProcessing ? null : _deleteThumbnail,
                                icon: const Icon(Icons.delete_rounded),
                                label: const Text('Șterge'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: ResponsiveService.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informații de bază',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                        ),
                      ),
                      SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                      Text(
                        'Informațiile principale despre carte/manual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: ResponsiveService.isSmallPhone ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
            
            // Title Field
            _buildStyledTextField(
              controller: _nameController,
              labelText: 'Titlu *',
              icon: Icons.title_rounded,
              enabled: !_isProcessing,
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
            
            // Author Field
            _buildStyledTextField(
              controller: _authorController,
              labelText: 'Autor *',
              icon: Icons.person_rounded,
              enabled: !_isProcessing,
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
            
            // Type Selection
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tip *',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                    padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 6 : 8),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: ResponsiveService.isSmallPhone ? 18 : 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveService.isSmallPhone ? 14 : 16, 
                    vertical: ResponsiveService.isSmallPhone ? 14 : 16
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'carte', child: Text('Carte')),
                  DropdownMenuItem(value: 'manual', child: Text('Manual')),
                ],
                onChanged: _isProcessing ? null : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      if (value == 'carte') {
                        _selectedClass = null;
                        _pdfUrl = null;
                      }
                    });
                  }
                },
                style: TextStyle(
                  fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // Class Selection (for manuals only)
            if (_selectedType == 'manual') ...[
              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Clasa',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 6 : 8),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: ResponsiveService.isSmallPhone ? 18 : 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveService.isSmallPhone ? 14 : 16, 
                      vertical: ResponsiveService.isSmallPhone ? 14 : 16
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Selectează clasa'),
                    ),
                    const DropdownMenuItem<String>(
                      enabled: false,
                      child: Text('Gimnaziu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...['V', 'VI', 'VII', 'VIII'].map((clasa) => DropdownMenuItem<String>(
                      value: clasa,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(clasa),
                      ),
                    )),
                    const DropdownMenuItem<String>(
                      enabled: false,
                      child: Text('Liceu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...['IX', 'X', 'XI', 'XII'].map((clasa) => DropdownMenuItem<String>(
                      value: clasa,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(clasa),
                      ),
                    )),
                  ],
                  onChanged: _isProcessing ? null : (value) {
                    setState(() => _selectedClass = value);
                  },
                  style: TextStyle(
                    fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.details_rounded,
                    color: Theme.of(context).colorScheme.onSecondary,
                    size: ResponsiveService.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalii suplimentare',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                        ),
                      ),
                      SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                      Text(
                        'Informații opționale despre carte/manual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: ResponsiveService.isSmallPhone ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
            
            // Category Field
            _buildStyledTextField(
              controller: _categoryController,
              labelText: 'Categorie',
              icon: Icons.local_offer_rounded,
              enabled: !_isProcessing,
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
            
            // Description Field
            _buildStyledTextField(
              controller: _descriptionController,
              labelText: 'Descriere',
              icon: Icons.description_rounded,
              maxLines: ResponsiveService.isSmallPhone ? 3 : 4,
              enabled: !_isProcessing,
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
            
            // Publication Year Field
            _buildStyledTextField(
              controller: _yearController,
              labelText: 'An publicare',
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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: ResponsiveService.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informații stoc',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                        ),
                      ),
                      SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                      Text(
                        'Gestionarea stocului și inventarului',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: ResponsiveService.isSmallPhone ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
            
            // Stock and Inventory Fields
            if (ResponsiveService.isSmallPhone) ...[
              _buildStyledTextField(
                controller: _stockController,
                labelText: 'Stoc',
                icon: Icons.shopping_bag_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isProcessing,
              ),
              const SizedBox(height: 12),
              _buildStyledTextField(
                controller: _inventoryController,
                labelText: 'Inventar',
                icon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isProcessing,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _stockController,
                      labelText: 'Stoc',
                      icon: Icons.shopping_bag_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_isProcessing,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _inventoryController,
                      labelText: 'Inventar',
                      icon: Icons.inventory_2_rounded,
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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Theme.of(context).colorScheme.onSecondary,
                    size: ResponsiveService.isSmallPhone ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fișier PDF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                        ),
                      ),
                      SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                      Text(
                        'Fișierul PDF al manualului pentru citire',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: ResponsiveService.isSmallPhone ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
            
            // PDF Status and Actions
            if (_pdfUrl != null) ...[
              Container(
                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: ResponsiveService.isSmallPhone ? 18 : 20,
                    ),
                    SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
                    Expanded(
                      child: Text(
                        'PDF încărcat cu succes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
            ],
            
            // Action Buttons
            ResponsiveService.isSmallPhone
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _uploadPdf,
                          icon: Icon(Icons.upload_file_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                          label: Text(
                            _pdfUrl != null ? 'Schimbă PDF' : 'Încarcă PDF',
                            style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                              vertical: ResponsiveService.isSmallPhone ? 10 : 12,
                            ),
                          ),
                        ),
                      ),
                      if (_pdfUrl != null) ...[
                        SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _deletePdf,
                            icon: Icon(Icons.delete_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                            label: Text(
                              'Șterge PDF',
                              style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error),
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                                vertical: ResponsiveService.isSmallPhone ? 10 : 12,
                              ),
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
                          icon: const Icon(Icons.upload_file_rounded),
                          label: Text(_pdfUrl != null ? 'Schimbă PDF' : 'Încarcă PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      if (_pdfUrl != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _deletePdf,
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text('Șterge PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
            offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
        child: ResponsiveService.isSmallPhone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.cancel_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                    label: Text(
                      'Anulează',
                      style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 9 : 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveService.isSmallPhone ? 12 : 20,
                        vertical: ResponsiveService.isSmallPhone ? 12 : 16,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _updateBook,
                    icon: _isProcessing
                        ? SizedBox(
                            width: ResponsiveService.isSmallPhone ? 16 : 18,
                            height: ResponsiveService.isSmallPhone ? 16 : 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(Icons.save_rounded, size: ResponsiveService.isSmallPhone ? 16 : 18),
                    label: Text(
                      _isProcessing ? 'Se actualizează...' : 'Salvează modificările',
                      style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                        vertical: ResponsiveService.isSmallPhone ? 12 : 16,
                      ),
                      elevation: 4,
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
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Anulează'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _updateBook,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isProcessing ? 'Se actualizează...' : 'Salvează modificările'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
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
            fontSize: ResponsiveService.isSmallPhone ? 14 : null,
          ),
          helperStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: ResponsiveService.isSmallPhone ? 10 : 12,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
            padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 6 : 8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveService.isSmallPhone ? 18 : 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveService.isSmallPhone ? 14 : 16, 
            vertical: ResponsiveService.isSmallPhone ? 14 : 16
          ),
        ),
        style: TextStyle(
          fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
          fontWeight: FontWeight.w500,
          color: enabled 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
} 