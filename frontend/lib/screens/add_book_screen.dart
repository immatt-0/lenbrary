import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen>
    with TickerProviderStateMixin {
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
  String _selectedType = 'carte'; // Default to 'carte'
  String? _selectedClass; // For manuals only
  String? _pdfUrl; // For PDF upload

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
        // Create the book through API
        await ApiService.addBook(
          name: _nameController.text,
          author: _authorController.text,
          inventory: int.parse(_inventoryController.text),
          stock: int.parse(_stockController.text),
          description: _descriptionController.text,
          category: _categoryController.text,
          type: _selectedType,
          publicationYear: _yearController.text.isNotEmpty
              ? int.parse(_yearController.text)
              : null,
          thumbnailUrl: _thumbnailUrl,
          bookClass: _selectedClass,
          pdfUrl: _pdfUrl,
        );

        if (!mounted) return;

        // Show success message
        NotificationService.showSuccess(
          context: context,
          message: 'Cartea/manualul a fost adăugat cu succes!',
        );

        // Clear the form
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
        await _processSelectedImage(image);
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
        await _processSelectedImage(image);
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la accesarea galeriei: ${e.toString()}',
      );
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Processing selected image...');
      debugPrint('Image path: ${image.path}');
      debugPrint('Image name: ${image.name}');
      debugPrint('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      
      String url;
      
      if (kIsWeb) {
        // For web, read the file as bytes
        debugPrint('Reading image as bytes for web...');
        final bytes = await image.readAsBytes();
        debugPrint('Image bytes length: ${bytes.length}');
        url = await ApiService.uploadThumbnail(bytes);
      } else {
        // For mobile, use the file path
        debugPrint('Using image path for mobile...');
        url = await ApiService.uploadThumbnail(image.path);
      }
      
      debugPrint('Upload successful, URL: $url');
      
      setState(() {
        _thumbnailUrl = url;
      });

      NotificationService.showSuccess(
        context: context,
        message: 'Coperta a fost încărcată cu succes!',
      );
    } catch (e) {
      debugPrint('Error in _processSelectedImage: $e');
      NotificationService.showError(
        context: context,
        message: 'Eroare la încărcarea copertei: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
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
          // For web, we need to get the bytes
          if (file.bytes != null) {
            await _processSelectedPdfBytes(file.bytes!, file.name);
          } else {
            NotificationService.showError(
              context: context,
              message: 'Eroare la citirea fișierului PDF',
            );
          }
        } else {
          // For mobile, we use the file path
          if (file.path != null) {
            await _processSelectedPdfPath(file.path!);
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

  Future<void> _processSelectedPdfBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Processing selected PDF bytes...');
      debugPrint('PDF name: $fileName');
      debugPrint('PDF bytes length: ${bytes.length}');
      
      final url = await ApiService.uploadPdf(bytes);
      
      debugPrint('PDF upload successful, URL: $url');
      
      setState(() {
        _pdfUrl = url;
      });

      NotificationService.showSuccess(
        context: context,
        message: 'PDF-ul a fost încărcat cu succes!',
      );
    } catch (e) {
      debugPrint('Error in _processSelectedPdfBytes: $e');
      NotificationService.showError(
        context: context,
        message: 'Eroare la încărcarea PDF-ului: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processSelectedPdfPath(String filePath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Processing selected PDF from path...');
      debugPrint('PDF path: $filePath');
      
      final url = await ApiService.uploadPdf(filePath);
      
      debugPrint('PDF upload successful, URL: $url');
      
      setState(() {
        _pdfUrl = url;
      });

      NotificationService.showSuccess(
        context: context,
        message: 'PDF-ul a fost încărcat cu succes!',
      );
    } catch (e) {
      debugPrint('Error in _processSelectedPdfPath: $e');
      NotificationService.showError(
        context: context,
        message: 'Eroare la încărcarea PDF-ului: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
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
                  Icons.library_add_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Adaugă Carte sau Manual Nou',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 32.0),
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
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                      Icons.library_add_rounded,
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
                                          'Informații Carte/Manual',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Completează detaliile cărții/manualului pentru a le adăuga în catalog',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      ),

                      // Form Container
                      Container(
                        width: 500,
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
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Book Thumbnail
                                _buildThumbnailSection(),
                                const SizedBox(height: 32.0),

                                // Form Fields
                                _buildFormFields(),

                                // Error message
                                if (_errorMessage != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16.0),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: Theme.of(context).colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 32.0),

                                // Action Buttons
                                _buildActionButtons(),
                              ],
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
    );
  }

  Widget _buildThumbnailSection() {
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
        onTap: _uploadThumbnail,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          height: 280,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _thumbnailUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      );
                    },
                  ),
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
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildFormField(
          controller: _nameController,
          label: 'Titlu',
          icon: Icons.title_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vă rugăm să introduceți titlul cărții/manualului';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildFormField(
          controller: _authorController,
          label: 'Autor',
          icon: Icons.person_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vă rugăm să introduceți numele autorului';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildTypeDropdown(),
        const SizedBox(height: 16.0),
        _buildClassDropdown(),
        const SizedBox(height: 16.0),
        // Show PDF upload only for manuals
        if (_selectedType == 'manual') ...[
          _buildPdfUploadWidget(),
          const SizedBox(height: 16.0),
        ],
        _buildFormField(
          controller: _inventoryController,
          label: 'Număr inventar',
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vă rugăm să introduceți numărul de inventar';
            }
            if (int.tryParse(value) == null) {
              return 'Număr invalid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildFormField(
          controller: _stockController,
          label: 'Număr exemplare',
          icon: Icons.book_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vă rugăm să introduceți numărul de exemplare';
            }
            if (int.tryParse(value) == null) {
              return 'Număr invalid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildFormField(
          controller: _categoryController,
          label: 'Categorie',
          icon: Icons.category_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vă rugăm să introduceți categoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildFormField(
          controller: _yearController,
          label: 'An publicare',
          icon: Icons.calendar_today_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value!.isNotEmpty) {
              final year = int.tryParse(value);
              if (year == null) {
                return 'An invalid';
              }
              final currentYear = DateTime.now().year;
              if (year < 1000 || year > currentYear) {
                return 'Interval an invalid';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        _buildFormField(
          controller: _descriptionController,
          label: 'Descriere (opțional)',
          icon: Icons.description_rounded,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
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
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _addBook,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isLoading ? 'Se salvează...' : 'Salvează'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Anulează'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
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
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: InputDecoration(
          labelText: 'Tip',
          labelStyle: TextStyle(
            color: Colors.grey[600],
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
              Icons.book_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: [
          DropdownMenuItem(
            value: 'carte',
            child: Row(
              children: [
                Icon(Icons.book_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Carte'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'manual',
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Manual'),
              ],
            ),
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedType = newValue!;
            // Reset class when type changes
            if (_selectedType == 'carte') {
              _selectedClass = null;
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vă rugăm să selectați tipul';
          }
          return null;
        },
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_selectedType != 'manual') {
      return const SizedBox.shrink();
    }

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
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedClass,
        decoration: InputDecoration(
          labelText: 'Clasă *',
          labelStyle: TextStyle(
            color: Colors.grey[600],
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
                  Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: [
          // Gimnaziu classes
          const DropdownMenuItem(value: 'V', child: Text('V - Gimnaziu')),
          const DropdownMenuItem(value: 'VI', child: Text('VI - Gimnaziu')),
          const DropdownMenuItem(value: 'VII', child: Text('VII - Gimnaziu')),
          const DropdownMenuItem(value: 'VIII', child: Text('VIII - Gimnaziu')),
          // Liceu classes
          const DropdownMenuItem(value: 'IX', child: Text('IX - Liceu')),
          const DropdownMenuItem(value: 'X', child: Text('X - Liceu')),
          const DropdownMenuItem(value: 'XI', child: Text('XI - Liceu')),
          const DropdownMenuItem(value: 'XII', child: Text('XII - Liceu')),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedClass = newValue;
          });
        },
        validator: (value) {
          if (_selectedType == 'manual' && (value == null || value.isEmpty)) {
            return 'Vă rugăm să selectați clasa pentru manual';
          }
          return null;
        },
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
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
          child: _pdfUrl != null
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
                              'PDF încărcat',
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
