import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';
import '../services/responsive_service.dart';
import 'dart:typed_data';

// NOTE: Photo and PDF uploads are now deferred until the user presses the Add Book button. The Add Book button is always visible and functional.

enum BookType { carte, manual }

extension BookTypeExtension on BookType {
  String get apiValue => this == BookType.carte ? 'carte' : 'manual';
  
  String getLabel(BuildContext context) => this == BookType.carte 
    ? AppLocalizations.of(context)!.book 
    : AppLocalizations.of(context)!.manual;
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
  BookType _selectedType = BookType.carte; // Default to carte
  String? _selectedClass; // For manuals only

  // List of available classes for manuals
  final List<String> _availableClasses = [
    'Gimnaziu V',
    'Gimnaziu VI',
    'Gimnaziu VII',
    'Gimnaziu VIII',
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
          } else if (kIsWeb && _pendingThumbnailFile != null) {
            // For web, read bytes from XFile
            final bytes = await _pendingThumbnailFile!.readAsBytes();
            thumbnailUrl = await ApiService.uploadThumbnail(bytes);
          } else if (_pendingThumbnailFile != null) {
            // For mobile, use file path
            thumbnailUrl = await ApiService.uploadThumbnail(_pendingThumbnailFile!.path);
          }
        }
        // Upload PDF if picked
        String? pdfUrl;
        if (_pendingPdfFile != null || _pendingPdfBytes != null) {
          if (kIsWeb && _pendingPdfBytes != null) {
            pdfUrl = await ApiService.uploadPdf(_pendingPdfBytes!);
          } else if (kIsWeb && _pendingPdfFile != null && _pendingPdfFile!.bytes != null) {
            // For web, use bytes from PlatformFile
            pdfUrl = await ApiService.uploadPdf(_pendingPdfFile!.bytes!);
          } else if (_pendingPdfFile != null && _pendingPdfFile!.path != null) {
            // For mobile, use file path
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
          message: AppLocalizations.of(context)!.bookAddedSuccessfully,
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
              Text(AppLocalizations.of(context)!.addCover),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.chooseCoverMethod,
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
                  AppLocalizations.of(context)!.takePicture,
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
                  AppLocalizations.of(context)!.addFromGallery,
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
                child: Text(
                  AppLocalizations.of(context)!.cancel,
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
        message: '${AppLocalizations.of(context)!.errorCameraAccess}: ${e.toString()}',
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
        message: '${AppLocalizations.of(context)!.errorGalleryAccess}: ${e.toString()}',
      );
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
              Text(AppLocalizations.of(context)!.addPdf),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.choosePdfForManual,
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
                  AppLocalizations.of(context)!.choosePdfForManual,
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
                child: Text(
                  AppLocalizations.of(context)!.cancel,
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
              message: '${AppLocalizations.of(context)!.errorReadingPdf}: ${file.name}',
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
              message: AppLocalizations.of(context)!.errorSelectingPdf,
            );
          }
        }
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: '${AppLocalizations.of(context)!.errorSelectingPdf}: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
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
                Icons.library_add_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: getResponsiveIconSize(24),
              ),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
            Text(
              AppLocalizations.of(context)!.addNewBook,
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
            tooltip: AppLocalizations.of(context)!.back,
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: getResponsivePadding(all: 16),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveService.cardMaxWidth,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header Section
                              _buildHeaderSection(),
                              SizedBox(height: getResponsiveSpacing(24)),
                              
                              // Cover Upload Section
                              _buildCoverUploadSection(),
                              SizedBox(height: getResponsiveSpacing(24)),

                              // Basic Information Section
                              _buildBasicInfoSection(),
                              SizedBox(height: getResponsiveSpacing(24)),

                              // Additional Details Section
                              _buildAdditionalDetailsSection(),
                              SizedBox(height: getResponsiveSpacing(24)),

                              // Stock Information Section
                              _buildStockInfoSection(),
                              
                              // PDF Upload Section (only for manuals)
                              if (_selectedType == BookType.manual) ...[
                                SizedBox(height: getResponsiveSpacing(24)),
                                _buildPdfUploadSection(),
                              ],

                              // Error Message
                              if (_errorMessage != null) ...[
                                SizedBox(height: getResponsiveSpacing(16)),
                                Container(
                                  padding: getResponsivePadding(all: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                    borderRadius: getResponsiveBorderRadius(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Theme.of(context).colorScheme.error,
                                        size: getResponsiveIconSize(20),
                                      ),
                                      SizedBox(width: getResponsiveSpacing(8)),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Action Buttons
                              SizedBox(height: getResponsiveSpacing(32)),
                              _buildActionButtons(),
                              SizedBox(height: getResponsiveSpacing(16)),
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
      ),
    );
  }

  // Header Section
  Widget _buildHeaderSection() {
    return Container(
      padding: getResponsivePadding(all: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: getResponsiveBorderRadius(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_books_rounded,
            size: getResponsiveIconSize(48),
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: getResponsiveSpacing(12)),
          Text(
            AppLocalizations.of(context)!.fillBookDetails,
            textAlign: TextAlign.center,
            style: ResponsiveTextStyles.getResponsiveTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: getResponsiveSpacing(8)),
          Text(
            AppLocalizations.of(context)!.requiredFields,
            textAlign: TextAlign.center,
            style: ResponsiveTextStyles.getResponsiveTextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Cover Upload Section
  Widget _buildCoverUploadSection() {
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(8),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: getResponsiveIconSize(20),
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  '${AppLocalizations.of(context)!.cover} (${AppLocalizations.of(context)!.optional})',
                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(16)),
            Center(child: _buildThumbnailSection()),
          ],
        ),
      ),
    );
  }

  // Basic Information Section
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: getResponsiveIconSize(20),
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  AppLocalizations.of(context)!.basicInformation,
                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(20)),
            
            // Type Selection
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                borderRadius: getResponsiveBorderRadius(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: DropdownButtonFormField<BookType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.resourceType,
                  labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(getResponsiveSpacing(8)),
                    padding: EdgeInsets.all(getResponsiveSpacing(8)),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: getResponsiveBorderRadius(8),
                    ),
                    child: Icon(
                      _selectedType == BookType.manual ? Icons.menu_book_rounded : Icons.book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: getResponsiveIconSize(20),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: getResponsivePadding(horizontal: 16, vertical: 16),
                ),
                items: BookType.values.map((type) {
                  return DropdownMenuItem<BookType>(
                    value: type,
                    child: Text(
                      type.getLabel(context),
                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            ),
            
            // Class Selection (for manuals only)
            if (_selectedType == BookType.manual) ...[
              SizedBox(height: getResponsiveSpacing(16)),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.03),
                  borderRadius: getResponsiveBorderRadius(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.classLevel} *',
                    labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(getResponsiveSpacing(8)),
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: getResponsiveBorderRadius(8),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: getResponsiveIconSize(20),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: getResponsivePadding(horizontal: 16, vertical: 16),
                  ),
                  items: _availableClasses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  },
                  validator: (value) => _selectedType == BookType.manual && value == null
                      ? AppLocalizations.of(context)!.pleaseSelectClass
                      : null,
                ),
              ),
            ],
            
            SizedBox(height: getResponsiveSpacing(16)),
            
            // Title Field
            _buildStyledTextField(
              controller: _nameController,
              label: AppLocalizations.of(context)!.title,
              icon: Icons.title_rounded,
              validator: (value) => value?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterTitle : null,
            ),
            
            SizedBox(height: getResponsiveSpacing(16)),
            
            // Author Field
            _buildStyledTextField(
              controller: _authorController,
              label: AppLocalizations.of(context)!.author,
              icon: Icons.person_rounded,
              validator: (value) => value?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterAuthor : null,
            ),
          ],
        ),
      ),
    );
  }

  // Additional Details Section
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(8),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: getResponsiveIconSize(20),
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  AppLocalizations.of(context)!.additionalDetails,
                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(20)),
            
            // Category Field
            _buildStyledTextField(
              controller: _categoryController,
              label: AppLocalizations.of(context)!.category,
              icon: Icons.category_rounded,
              validator: (value) => value?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterCategory : null,
            ),
            
            SizedBox(height: getResponsiveSpacing(16)),
            
            // Description Field
            _buildStyledTextField(
              controller: _descriptionController,
              label: AppLocalizations.of(context)!.description,
              icon: Icons.notes_rounded,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterDescription : null,
            ),
            
            SizedBox(height: getResponsiveSpacing(16)),
            
            // Publication Year Field
            _buildStyledTextField(
              controller: _yearController,
              label: '${AppLocalizations.of(context)!.publicationYear} (${AppLocalizations.of(context)!.optional})',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final year = int.tryParse(value);
                  if (year == null || year < 1000 || year > DateTime.now().year) {
                    return AppLocalizations.of(context)!.pleaseEnterValidYear;
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Stock Information Section
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: getResponsiveIconSize(20),
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  AppLocalizations.of(context)!.stockInformation,
                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(20)),
            
            // Stock and Inventory Fields
            if (ResponsiveService.isSmallPhone) ...[
              // Stack vertically on small phones
              _buildStyledTextField(
                controller: _inventoryController,
                label: AppLocalizations.of(context)!.inventory,
                icon: Icons.library_books_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterTotalInventory;
                  if (int.tryParse(value) == null) return AppLocalizations.of(context)!.inventoryMustBeNumber;
                  return null;
                },
                keyboardType: TextInputType.number,
                helperText: AppLocalizations.of(context)!.totalCopies,
              ),
              SizedBox(height: getResponsiveSpacing(16)),
              _buildStyledTextField(
                controller: _stockController,
                label: AppLocalizations.of(context)!.stock,
                icon: Icons.inventory_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterAvailableStock;
                  final stock = int.tryParse(value);
                  if (stock == null) return AppLocalizations.of(context)!.stockMustBeNumber;
                  final inventory = int.tryParse(_inventoryController.text);
                  if (inventory != null && stock > inventory) {
                    return AppLocalizations.of(context)!.stockCannotExceedInventory;
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                helperText: AppLocalizations.of(context)!.availableCopies,
              ),
            ] else ...[
              // Side by side on larger screens
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _inventoryController,
                      label: AppLocalizations.of(context)!.totalInventory,
                      icon: Icons.library_books_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterTotalInventory;
                        if (int.tryParse(value) == null) return AppLocalizations.of(context)!.inventoryMustBeNumber;
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      helperText: AppLocalizations.of(context)!.totalCopies,
                    ),
                  ),
                  SizedBox(width: getResponsiveSpacing(16)),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: _stockController,
                      label: AppLocalizations.of(context)!.availableStock,
                      icon: Icons.inventory_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.pleaseEnterAvailableStock;
                        final stock = int.tryParse(value);
                        if (stock == null) return AppLocalizations.of(context)!.stockMustBeNumber;
                        final inventory = int.tryParse(_inventoryController.text);
                        if (inventory != null && stock > inventory) {
                          return AppLocalizations.of(context)!.stockCannotExceedInventory;
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      helperText: AppLocalizations.of(context)!.availableCopies,
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

  // PDF Upload Section
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: getResponsiveIconSize(20),
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.manualPDF} (${AppLocalizations.of(context)!.optional})',
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Text(
                        'Încarcă fișierul PDF al manualului',
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(16)),
            _buildPdfUploadWidget(),
          ],
        ),
      ),
    );
  }

  // Action Buttons
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
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(16),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 20),
        child: ResponsiveService.isSmallPhone
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cancel Button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: getResponsiveIconSize(20),
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: getResponsivePadding(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: getResponsiveBorderRadius(12),
                      ),
                    ),
                  ),
                  SizedBox(height: getResponsiveSpacing(12)),
                  // Add Book Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addBook,
                    icon: _isLoading
                        ? SizedBox(
                            height: getResponsiveIconSize(20),
                            width: getResponsiveIconSize(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.add_rounded,
                            size: getResponsiveIconSize(20),
                          ),
                    label: Text(
                      _isLoading 
                          ? AppLocalizations.of(context)!.adding
                          : AppLocalizations.of(context)!.addItem(_selectedType.getLabel(context)),
                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: getResponsivePadding(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: getResponsiveBorderRadius(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  // Cancel Button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.cancel_rounded,
                        size: getResponsiveIconSize(20),
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: getResponsivePadding(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: getResponsiveBorderRadius(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: getResponsiveSpacing(16)),
                  // Add Book Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addBook,
                      icon: _isLoading
                          ? SizedBox(
                              height: getResponsiveIconSize(20),
                              width: getResponsiveIconSize(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add_rounded,
                              size: getResponsiveIconSize(20),
                            ),
                      label: Text(
                        _isLoading 
                            ? AppLocalizations.of(context)!.adding
                            : AppLocalizations.of(context)!.addItem(_selectedType.getLabel(context)),
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: getResponsivePadding(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: getResponsiveBorderRadius(12),
                        ),
                        elevation: 2,
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
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: getResponsiveBorderRadius(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
          helperText: helperText,
          helperStyle: ResponsiveTextStyles.getResponsiveTextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(getResponsiveSpacing(8)),
            padding: EdgeInsets.all(getResponsiveSpacing(8)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: getResponsiveBorderRadius(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(20),
            ),
          ),
          border: InputBorder.none,
          contentPadding: getResponsivePadding(horizontal: 16, vertical: 16),
          errorStyle: ResponsiveTextStyles.getResponsiveTextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: ResponsiveTextStyles.getResponsiveTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Container(
      width: getResponsiveSpacing(160),
      height: getResponsiveSpacing(240),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: getResponsiveBorderRadius(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: getResponsiveSpacing(12),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _uploadThumbnail,
          borderRadius: getResponsiveBorderRadius(16),
          child: Container(
            child: _pendingThumbnailFile != null || _pendingThumbnailBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: getResponsiveBorderRadius(14),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: kIsWeb 
                              ? (_pendingThumbnailBytes != null
                                  ? Image.memory(
                                      _pendingThumbnailBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ))
                              : (_pendingThumbnailFile != null
                                  ? FutureBuilder<Uint8List>(
                                      future: _pendingThumbnailFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          ),
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    )),
                        ),
                      ),
                      // Overlay with edit icon
                      Positioned(
                        top: getResponsiveSpacing(8),
                        right: getResponsiveSpacing(8),
                        child: Container(
                          padding: EdgeInsets.all(getResponsiveSpacing(6)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: getResponsiveBorderRadius(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: getResponsiveIconSize(16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(getResponsiveSpacing(16)),
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
                          size: getResponsiveIconSize(40),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: getResponsiveSpacing(12)),
                      Text(
                        AppLocalizations.of(context)!.addCover,
                        textAlign: TextAlign.center,
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: getResponsiveSpacing(4)),
                      Text(
                        AppLocalizations.of(context)!.tapToUpload,
                        textAlign: TextAlign.center,
                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
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
        borderRadius: getResponsiveBorderRadius(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(12),
            offset: Offset(0, getResponsiveSpacing(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _uploadPdf,
          borderRadius: getResponsiveBorderRadius(16),
          child: Container(
            width: double.infinity,
            padding: getResponsivePadding(all: 20),
            child: _pendingPdfFile != null || _pendingPdfBytes != null
                ? Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(getResponsiveSpacing(12)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: getResponsiveBorderRadius(12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: getResponsiveIconSize(32),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(width: getResponsiveSpacing(16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.pdfSuccessfullyAdded,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            SizedBox(height: getResponsiveSpacing(4)),
                            Text(
                              kIsWeb && _pendingPdfBytes != null
                                  ? AppLocalizations.of(context)!.pdfFileSize((_pendingPdfBytes!.length / 1024).toStringAsFixed(1))
                                  : AppLocalizations.of(context)!.pdfFileSelected,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: getResponsiveSpacing(4)),
                            Text(
                              AppLocalizations.of(context)!.tapToChange,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(getResponsiveSpacing(8)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: getResponsiveBorderRadius(20),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: getResponsiveIconSize(24),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(getResponsiveSpacing(12)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: getResponsiveBorderRadius(12),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: getResponsiveIconSize(32),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(width: getResponsiveSpacing(16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.uploadPdfFile,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            SizedBox(height: getResponsiveSpacing(4)),
                            Text(
                              AppLocalizations.of(context)!.selectManualPdfFile,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: getResponsiveSpacing(4)),
                            Text(
                              AppLocalizations.of(context)!.tapToUpload,
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(getResponsiveSpacing(8)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: getResponsiveBorderRadius(20),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: getResponsiveIconSize(24),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
