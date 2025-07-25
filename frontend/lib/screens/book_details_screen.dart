import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/responsive_service.dart' show ResponsiveWidget, getResponsiveSpacing, getResponsiveBorderRadius, getResponsiveIconSize, ResponsiveTextStyles;

class BookDetailsScreen extends StatefulWidget {
  final dynamic book;
  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> with ResponsiveWidget {
  bool _isRequesting = false;

  Future<void> _requestLoanWithDialog() async {
    int selectedDuration = 14; // Default to 2 weeks
    String? userMessage;
    final durations = [
      {'label': '1 Săptămână', 'value': 7},
      {'label': '2 Săptămâni', 'value': 14},
      {'label': '1 Lună', 'value': 30},
      {'label': '2 Luni', 'value': 60},
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicită împrumut'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durata împrumutului', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                      ),
                      child: DropdownButton<int>(
                        value: selectedDuration,
                        isExpanded: true,
                        underline: SizedBox(),
                        items: durations.map((d) => DropdownMenuItem<int>(
                          value: d['value'] as int,
                          child: Text(d['label'] as String),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => selectedDuration = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Mesaj (opțional)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Scrie un mesaj pentru bibliotecar... (opțional)',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 4,
                      maxLines: 6,
                      onChanged: (value) => userMessage = value,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'duration': selectedDuration,
                'message': userMessage,
              }),
              child: const Text('Confirmă'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _requestLoan(duration: result['duration'], message: result['message']);
    }
  }

  Future<void> _requestLoan({int duration = 14, String? message}) async {
    setState(() { _isRequesting = true; });
    try {
      await ApiService.requestBook(
        bookId: widget.book['id'],
        loanDurationDays: duration,
        message: message,
      );
      if (!mounted) return;
      NotificationService.showSuccess(
        context: context,
        message: 'Cerere de împrumut înregistrată cu succes!',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context: context,
        message: 'Eroare la solicitarea cărții/manualului: ${e.toString()}',
      );
    } finally {
      setState(() { _isRequesting = false; });
    }
  }

  void _viewPdf(String pdfUrl) async {
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        NotificationService.showError(
          context: context,
          message: 'Nu s-a putut deschide PDF-ul.',
        );
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la deschiderea PDF-ului: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final pdfUrl = book['pdf_file'] != null && book['pdf_file'].toString().isNotEmpty
        ? (book['pdf_file'].toString().startsWith('http')
            ? book['pdf_file']
            : ApiService.baseUrl + book['pdf_file'])
        : null;
    final thumbnailUrl = book['thumbnail_url'] != null && book['thumbnail_url'].toString().isNotEmpty
        ? (book['thumbnail_url'].toString().startsWith('http')
            ? book['thumbnail_url']
            : ApiService.baseUrl + '/media/' + book['thumbnail_url'].toString().replaceAll(RegExp(r'^/?media/'), ''))
        : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Container(
          margin: EdgeInsets.only(left: getResponsiveSpacing(20), top: getResponsiveSpacing(8), bottom: getResponsiveSpacing(8)),
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
                Icons.menu_book_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: getResponsiveIconSize(24),
              ),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
            Text(
              'Detalii Carte',
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
                // Book cover and info card
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Book cover
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: thumbnailUrl != null
                                ? Image.network(
                                    thumbnailUrl,
                                    width: 100,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 100,
                                    height: 140,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                    child: Icon(Icons.book_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                                  ),
                          ),
                          const SizedBox(width: 24),
                          // Book details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['name'] ?? 'Carte necunoscută',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book['author'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (book['category'] != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.category_rounded, size: 18, color: Theme.of(context).colorScheme.secondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        book['category'],
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (book['book_class'] != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.school_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Clasa: ${book['book_class']}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (book['available_copies'] != null && book['type'] != 'manual') ...[
                                  if (book['available_copies'] > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2_rounded, size: 18, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(
                                           'Disponibile: ${book['available_copies']}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (book['available_copies'] == 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2_rounded, size: 18, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Indisponibil',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Description card
                if (book['description'] != null && book['description'].toString().isNotEmpty && book['type'] != 'manual')
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
                            child: Text(
                              book['description'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (pdfUrl != null) ...[
                  const SizedBox(height: 20),
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
                            child: ElevatedButton(
                              onPressed: () => _viewPdf(pdfUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text('Deschide PDF'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Loan button - only show for non-manual books
                if (book['type'] != 'manual')
                  ElevatedButton.icon(
                    onPressed: (_isRequesting || 
                               (book['available_copies'] != null && book['available_copies'] == 0)) ? null : _requestLoanWithDialog,
                    icon: _isRequesting
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.shopping_cart_rounded),
                    label: Text(_isRequesting 
                        ? 'Se trimite...' 
                        : 'Solicită împrumut'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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