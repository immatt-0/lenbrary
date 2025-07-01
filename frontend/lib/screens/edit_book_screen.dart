import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart' show ResponsiveWidget, getResponsiveSpacing, getResponsiveBorderRadius, getResponsiveIconSize, ResponsiveTextStyles;
import 'package:file_picker/file_picker.dart';

class EditBookScreen extends StatefulWidget {
  final dynamic book;
  const EditBookScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> with ResponsiveWidget {
  late TextEditingController _nameController;
  late TextEditingController _authorController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _yearController;
  late TextEditingController _stockController;
  late TextEditingController _inventoryController;
  late TextEditingController _classController;
  late TextEditingController _pdfController;
  String _selectedType = 'carte';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _nameController = TextEditingController(text: book['name'] ?? '');
    _authorController = TextEditingController(text: book['author'] ?? '');
    _categoryController = TextEditingController(text: book['category'] ?? '');
    _descriptionController = TextEditingController(text: book['description'] ?? '');
    _yearController = TextEditingController(text: book['publication_year']?.toString() ?? '');
    _stockController = TextEditingController(text: book['stock']?.toString() ?? '');
    _inventoryController = TextEditingController(text: book['inventory']?.toString() ?? '');
    _classController = TextEditingController(text: book['book_class']?.toString() ?? '');
    _pdfController = TextEditingController(text: book['pdf_file']?.toString() ?? '');
    _selectedType = book['type'] ?? 'carte';
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
    _classController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    setState(() => _isSaving = true);
    try {
      final pdfValue = _pdfController.text.trim().isEmpty ? null : _pdfController.text.trim();
      await ApiService.updateBook(
        bookId: widget.book['id'],
        name: _nameController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim(),
        publicationYear: int.tryParse(_yearController.text.trim()),
        stock: int.tryParse(_stockController.text.trim()),
        inventory: int.tryParse(_inventoryController.text.trim()),
        bookClass: _classController.text.trim().isNotEmpty ? _classController.text.trim() : null,
        pdfUrl: pdfValue,
      );
      if (mounted) {
        NotificationService.showSuccess(
          context: context,
          message: 'Cartea a fost actualizată cu succes!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context: context,
          message: 'Eroare la actualizarea cărții: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Container(
          margin: EdgeInsets.only(left: getResponsiveSpacing(20), top: getResponsiveSpacing(8), bottom: getResponsiveSpacing(8)),
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: getResponsiveBorderRadius(6),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(20),
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Înapoi',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: getResponsiveSpacing(8),
                    offset: Offset(0, getResponsiveSpacing(2)),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: getResponsiveIconSize(24),
              ),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
            Text(
              'Editează Carte',
              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main card with cover and editable fields
                Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Book cover (top, centered)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.book['thumbnail_url'] != null && widget.book['thumbnail_url'].toString().isNotEmpty
                                  ? Image.network(
                                      widget.book['thumbnail_url'].toString().startsWith('http')
                                          ? widget.book['thumbnail_url']
                                          : ApiService.baseUrl + '/media/' + widget.book['thumbnail_url'].toString().replaceAll(RegExp(r'^/?media/'), ''),
                                      width: 120,
                                      height: 170,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 120,
                                      height: 170,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                      child: Icon(Icons.book_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Editable book details (stretched wide)
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Titlu',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: 'Autor',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Categorie',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Tip',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'carte', child: Text('Carte')),
                              DropdownMenuItem(value: 'manual', child: Text('Manual')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedType = value);
                            },
                          ),
                          if (_selectedType == 'manual') ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _classController.text.isNotEmpty ? _classController.text : null,
                              decoration: const InputDecoration(
                                labelText: 'Clasa',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem<String>(
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
                                DropdownMenuItem<String>(
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
                              onChanged: (value) {
                                if (value != null) setState(() => _classController.text = value);
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'An publicare',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stoc',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inventoryController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Inventar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Description field
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description_rounded, color: Theme.of(context).colorScheme.secondary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            minLines: 2,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Descriere',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // PDF field (only for manuals)
                if (_selectedType == 'manual')
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface.withOpacity(0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).colorScheme.tertiary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pdfController,
                              decoration: const InputDecoration(
                                labelText: 'PDF (URL sau cale)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Save button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBook,
                  icon: Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Se salvează...' : 'Salvează'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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