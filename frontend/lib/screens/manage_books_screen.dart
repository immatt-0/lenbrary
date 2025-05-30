import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

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

class _UpdateBookDialogState extends State<UpdateBookDialog> {
  late final TextEditingController _stockController;
  late final TextEditingController _inventoryController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _stockController =
        TextEditingController(text: widget.book['stock'].toString());
    _inventoryController =
        TextEditingController(text: widget.book['inventory'].toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    _inventoryController.dispose();
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
    } catch (e) {
      if (!mounted) return;

      // Show error and stay on dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Actualizare "${widget.book['name']}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Stoc disponibil',
              helperText: 'Numărul de exemplare disponibile pentru împrumut',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isProcessing,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inventoryController,
            decoration: const InputDecoration(
              labelText: 'Inventar total',
              helperText: 'Numărul total de exemplare din bibliotecă',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_isProcessing,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : _cancel,
          child: const Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _updateStock,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizează'),
        ),
      ],
    );
  }
}

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({Key? key}) : super(key: key);

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  List<dynamic> _books = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _processingAction = false;

  // Keep track of mounted state through async operations
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _updateState(VoidCallback action) {
    // Only update state if the widget is still mounted
    if (_isMounted && mounted) {
      setState(action);
    }
  }

  Future<void> _loadBooks() async {
    _updateState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await ApiService.getBooks();

      // Check mounted again after async operation
      if (!_isMounted || !mounted) return;

      _updateState(() {
        _books = books;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stocul cărții a fost actualizat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionare Cărți'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBooks,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _books.isEmpty
                  ? const Center(
                      child: Text('Nu există cărți'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return _buildBookCard(book);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add book screen
          Navigator.pushNamed(context, '/add-book').then((_) {
            // Only refresh if still mounted after return
            if (_isMounted && mounted) {
              _loadBooks();
            }
          });
        },
        tooltip: 'Adaugă carte',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookCard(dynamic book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book thumbnail
                if (book['thumbnail_url'] != null)
                  SizedBox(
                    width: 70,
                    height: 100,
                    child: Image.network(
                      book['thumbnail_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),

                const SizedBox(width: 16.0),

                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['name'] ?? 'Unknown title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'By: ${book['author'] ?? 'Autor necunoscut'}',
                      ),
                      if (book['category'] != null) ...[
                        const SizedBox(height: 4.0),
                        Text('Categorie: ${book['category']}'),
                      ],
                      const SizedBox(height: 4.0),
                      Text(
                        'Stoc: ${book['stock']} / Inventar: ${book['inventory']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Disponibile: ${book['available_copies'] ?? 0}',
                        style: TextStyle(
                          color: (book['available_copies'] ?? 0) > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _processingAction
                        ? null
                        : () => _showUpdateDialog(book),
                    icon: const Icon(Icons.edit),
                    label: const Text('Gestionare stoc'),
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
