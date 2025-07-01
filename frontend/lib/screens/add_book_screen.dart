import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';
import '../services/responsive_service.dart';
import 'dart:io';

// NOTE: Photo and PDF uploads are now deferred until the user presses the Add Book button. The Add Book button is always visible and functional.

enum BookType { carte, manual }

extension BookTypeExtension on BookType {
  String get label => this == BookType.carte ? 'Carte' : 'Manual';
  String get apiValue => this == BookType.carte ? 'carte' : 'manual';
}

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _inventoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _yearController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  String? _thumbnailUrl;
  BookType _selectedType = BookType.carte; // Default to carte
  String? _selectedClass; // For manuals only
  String? _pdfUrl; // For PDF upload

  // List of available classes for manuals
  final List<String> _availableClasses = [
    'Gimaziu V',
    'Gimaziu VI',
    'Gimaziu VII',
    'Gimaziu VIII',
    'Liceu IX',
    'Liceu X',
    'Liceu XI',
    'Liceu XII',
  ];

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  XFile? _pendingThumbnailFile; // Store picked image until save
  Uint8List? _pendingThumbnailBytes; // For web
  PlatformFile? _pendingPdfFile; // Store picked PDF until save
  Uint8List? _pendingPdfBytes; // For web

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
    _nameController.dispose();
    _authorController.dispose();
    _inventoryController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _yearController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _addBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        // Upload thumbnail if picked
        String? thumbnailUrl;
        if (_pendingThumbnailFile != null || _pendingThumbnailBytes != null) {
          if (kIsWeb && _pendingThumbnailBytes != null) {
            thumbnailUrl = await ApiService.uploadThumbnail(_pendingThumbnailBytes!);
          } else if (_pendingThumbnailFile != null) {
            thumbnailUrl = await ApiService.uploadThumbnail(_pendingThumbnailFile!.path);
          }
        }
        // Upload PDF if picked
        String? pdfUrl;
        if (_pendingPdfFile != null || _pendingPdfBytes != null) {
          if (kIsWeb && _pendingPdfBytes != null) {
            pdfUrl = await ApiService.uploadPdf(_pendingPdfBytes!);
          } else if (_pendingPdfFile != null && _pendingPdfFile!.path != null) {
            pdfUrl = await ApiService.uploadPdf(_pendingPdfFile!.path!);
          }
        }
        // Create the book through API
        await ApiService.addBook(
          name: _nameController.text,
          author: _authorController.text,
          inventory: int.parse(_inventoryController.text),
          stock: int.parse(_stockController.text),
          description: _descriptionController.text,
          category: _categoryController.text,
          type: _selectedType.apiValue,
          publicationYear: _yearController.text.isNotEmpty
              ? int.parse(_yearController.text)
              : null,
          thumbnailUrl: thumbnailUrl != null ? ApiService.extractRelativeMediaPath(thumbnailUrl) : null,
          bookClass: _selectedClass,
          pdfUrl: pdfUrl != null ? ApiService.extractRelativeMediaPath(pdfUrl) : null,
        );
        if (!mounted) return;
        NotificationService.showSuccess(
          context: context,
          message: 'Cartea/manualul a fost adăugat cu succes!',
        );
        // Clear the form and pending files
        _formKey.currentState!.reset();
        _nameController.clear();
        _authorController.clear();
        _inventoryController.clear();
        _stockController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        _yearController.clear();
        setState(() {
          _thumbnailUrl = null;
          _pdfUrl = null;
          _selectedType = BookType.carte;
          _selectedClass = null;
          _pendingThumbnailFile = null;
          _pendingThumbnailBytes = null;
          _pendingPdfFile = null;
          _pendingPdfBytes = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
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

  Future<void> _uploadThumbnail() async {
    // Show popup with camera and gallery options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Adaugă copertă'),
            ],
          ),
          content: const Text(
            'Alegeți cum doriți să adăugați coperta cărții:',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // Camera Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
                icon: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  'Fă o poză',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            // Gallery Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
                icon: Icon(Icons.photo_library_rounded, color: Theme.of(context).colorScheme.onSecondary),
                label: Text(
                  'Adaugă din galerie',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            // Cancel Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Anulează',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pendingThumbnailFile = image;
          _pendingThumbnailBytes = null;
        });
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la accesarea camerei: ${e.toString()}',
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pendingThumbnailFile = image;
          _pendingThumbnailBytes = null;
        });
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la accesarea galeriei: ${e.toString()}',
      );
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pendingThumbnailBytes = bytes;
        _pendingThumbnailFile = null;
      });
    } else {
      setState(() {
        _pendingThumbnailFile = image;
        _pendingThumbnailBytes = null;
      });
    }
  }

  Future<void> _uploadPdf() async {
    // Show popup with file picker options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Adaugă PDF'),
            ],
          ),
          content: const Text(
            'Alegeți fișierul PDF pentru manual:',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // File Picker Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickPdfFile();
                },
                icon: Icon(Icons.file_upload_rounded, color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  'Alege fișier PDF',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            // Cancel Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Anulează',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (kIsWeb) {
          if (file.bytes != null) {
            setState(() {
              _pendingPdfBytes = file.bytes;
              _pendingPdfFile = null;
            });
          } else {
            NotificationService.showError(
              context: context,
              message: 'Eroare la citirea fișierului PDF',
            );
          }
        } else {
          if (file.path != null) {
            setState(() {
              _pendingPdfFile = file;
              _pendingPdfBytes = null;
            });
          } else {
            NotificationService.showError(
              context: context,
              message: 'Eroare la accesarea fișierului PDF',
            );
          }
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
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: getResponsivePadding(horizontal: 16.0, vertical: 8.0),
            child: Row(
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
                    Icons.library_add_rounded,
                    size: getResponsiveIconSize(28),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  ResponsiveService.isCompactLayout ? 'Add Book' : 'Add New Book',
                  style: ResponsiveTextStyles.getResponsiveTitleStyle(
                    fontSize: ResponsiveService.isCompactLayout ? 20.0 : 24.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(getResponsiveSpacing(8)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: getResponsiveBorderRadius(8),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(24),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: getResponsivePadding(all: 16),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveService.cardMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo upload section first
                      _buildThumbnailSection(),
                      SizedBox(height: getResponsiveSpacing(24)),

                      // Type selection card
                      Container(
                        margin: EdgeInsets.only(bottom: getResponsiveSpacing(24)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: getResponsiveBorderRadius(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                              blurRadius: getResponsiveSpacing(24),
                              offset: Offset(0, getResponsiveSpacing(10)),
                              spreadRadius: 3,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: getResponsivePadding(all: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip resursă',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              DropdownButtonFormField<BookType>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  labelText: 'Tip resursă',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                ),
                                items: BookType.values.map((type) {
                                  return DropdownMenuItem<BookType>(
                                    value: type,
                                    child: Text(type.label),
                                  );
                                }).toList(),
                                onChanged: (BookType? newValue) {
                                  setState(() {
                                    _selectedType = newValue!;
                                    if (_selectedType == BookType.carte) {
                                      _selectedClass = null;
                                    }
                                  });
                                },
                              ),
                              if (_selectedType == BookType.manual) ...[
                                SizedBox(height: getResponsiveSpacing(16)),
                                DropdownButtonFormField<String>(
                                  value: _selectedClass,
                                  decoration: InputDecoration(
                                    labelText: 'Clasă',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                  ),
                                  items: _availableClasses.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedClass = newValue;
                                    });
                                  },
                                  validator: (value) => _selectedType == BookType.manual && value == null
                                      ? 'Please select a class'
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Title and Author card
                      Container(
                        margin: EdgeInsets.only(bottom: getResponsiveSpacing(24)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: getResponsiveBorderRadius(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                              blurRadius: getResponsiveSpacing(24),
                              offset: Offset(0, getResponsiveSpacing(10)),
                              spreadRadius: 3,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: getResponsivePadding(all: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Titlu',
                                validator: (value) => value?.isEmpty ?? true ? 'Vă rugăm să introduceți un titlu' : null,
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              _buildTextField(
                                controller: _authorController,
                                label: 'Autor',
                                validator: (value) => value?.isEmpty ?? true ? 'Vă rugăm să introduceți un autor' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Rest of the form fields
                      Container(
                        margin: EdgeInsets.only(bottom: getResponsiveSpacing(24)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: getResponsiveBorderRadius(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                              blurRadius: getResponsiveSpacing(24),
                              offset: Offset(0, getResponsiveSpacing(10)),
                              spreadRadius: 3,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: getResponsivePadding(all: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _categoryController,
                                label: 'Categorie',
                                validator: (value) => value?.isEmpty ?? true ? 'Vă rugăm să introduceți o categorie' : null,
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              _buildTextField(
                                controller: _descriptionController,
                                label: 'Descriere',
                                maxLines: 3,
                                validator: (value) => value?.isEmpty ?? true ? 'Vă rugăm să introduceți o descriere' : null,
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              _buildTextField(
                                controller: _inventoryController,
                                label: 'Inventar',
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Vă rugăm să introduceți un inventar';
                                  if (int.tryParse(value) == null) return 'Inventarul trebuie să fie un număr';
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              _buildTextField(
                                controller: _stockController,
                                label: 'Stoc',
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Vă rugăm să introduceți un stoc';
                                  if (int.tryParse(value) == null) return 'Stocul trebuie să fie un număr';
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PDF upload section (show only for manuals)
                      if (_selectedType == BookType.manual) ...[
                        SizedBox(height: getResponsiveSpacing(24)),
                        _buildPdfUploadWidget(),
                      ],

                      // Add more space before the buttons
                      SizedBox(height: getResponsiveSpacing(32)),

                      if (ResponsiveService.isCompactLayout)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: getResponsivePadding(vertical: 16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: getResponsiveBorderRadius(8),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: getResponsiveSpacing(12)),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addBook,
                                style: ElevatedButton.styleFrom(
                                  padding: getResponsivePadding(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: getResponsiveBorderRadius(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: getResponsiveIconSize(24),
                                        width: getResponsiveIconSize(24),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Adaugă carte',
                                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: getResponsivePadding(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: getResponsiveBorderRadius(8),
                                  ),
                                ),
                                child: Text(
                                  'Anulează',
                                  style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: getResponsiveSpacing(12)),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addBook,
                                style: ElevatedButton.styleFrom(
                                  padding: getResponsivePadding(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: getResponsiveBorderRadius(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: getResponsiveIconSize(24),
                                        width: getResponsiveIconSize(24),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Add Book',
                                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.title_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 280,
        child: Container(
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
          child: InkWell(
            onTap: _uploadThumbnail,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _pendingThumbnailFile != null || _pendingThumbnailBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb && _pendingThumbnailBytes != null
                          ? Image.memory(_pendingThumbnailBytes!, fit: BoxFit.cover)
                          : Image.file(File(_pendingThumbnailFile!.path), fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Adaugă copertă',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apasă pentru a încărca',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfUploadWidget() {
    return Container(
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
      child: InkWell(
        onTap: _uploadPdf,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _pendingPdfFile != null || _pendingPdfBytes != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'PDF selectat',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Apasă pentru a schimba',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Adaugă PDF',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Apasă pentru a încărca',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
