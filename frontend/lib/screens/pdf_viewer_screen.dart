import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/notification_service.dart';
import '../services/responsive_service.dart' show ResponsiveWidget, getResponsiveSpacing, getResponsiveBorderRadius, getResponsiveIconSize, ResponsiveTextStyles;
import 'package:path_provider/path_provider.dart'; // Add this import for cache directory
import 'package:crypto/crypto.dart'; // For hashing the URL
import 'dart:convert'; // For utf8.encode

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  
  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> with ResponsiveWidget {
  PDFViewController? _pdfViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoom = 1.0;
  bool _isFullScreen = false;
  Uint8List? _pdfBytes;
  bool _isMobile = false;
  String? _pdfFilePath; // Add this variable to your state
  final TextEditingController _pageController = TextEditingController(); // For page input

  @override
  void initState() {
    super.initState();
    _detectPlatform();
    _loadPdf();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _detectPlatform() {
    // Detect if we're on mobile (Android/iOS) vs desktop/web
    if (kIsWeb) {
      _isMobile = false; // Web is considered desktop
    } else {
      _isMobile = Platform.isAndroid || Platform.isIOS;
    }
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      if (_isMobile) {
        // Use a hash of the URL as the filename
        final urlHash = md5.convert(utf8.encode(widget.pdfUrl)).toString();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/pdfcache_$urlHash.pdf');
        if (await file.exists()) {
          // Use cached file
          _pdfFilePath = file.path;
        } else {
          // Download and cache the PDF
          final response = await http.get(Uri.parse(widget.pdfUrl));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes, flush: true);
            _pdfFilePath = file.path;
          } else {
            throw Exception('Failed to load PDF: ${response.statusCode}');
          }
        }
      } else {
        // For web, immediately open in browser
        _openInBrowser();
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onPageChanged(int? page, int? total) {
    if (page != null && total != null) {
      setState(() {
        _currentPage = page;
        _totalPages = total;
      });
    }
  }

  void _onZoomChanged(double zoom) {
    setState(() {
      _zoom = zoom;
    });
  }

  Future<void> _openInBrowser() async {
    try {
      final Uri url = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Close this screen since we opened in browser
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        NotificationService.showError(
          context: context,
          message: 'Nu s-a putut deschide PDF-ul în browser',
        );
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la deschiderea PDF-ului: $e',
      );
    }
  }

  Future<void> _openInExternalViewer() async {
    try {
      final Uri url = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        NotificationService.showError(
          context: context,
          message: 'Nu s-a putut deschide PDF-ul în aplicația externă',
        );
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la deschiderea PDF-ului: $e',
      );
    }
  }

  void _downloadPdf() {
    // For mobile, open in external viewer
    _openInExternalViewer();
  }

  @override
  Widget build(BuildContext context) {
    // For web, show a loading screen that automatically opens in browser
    if (!_isMobile) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Platform indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Web',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Se deschide PDF-ul în browser...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF-ul va fi deschis automat în browser-ul tău.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Deschide manual în browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Închide',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile PDF viewer
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen ? null : AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Platform indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Mobile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Page info
          if (_totalPages > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          
          // Zoom info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                '${(_zoom * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Full screen toggle
          IconButton(
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
            },
            tooltip: _isFullScreen ? 'Ieșire din ecran complet' : 'Ecran complet',
          ),
          
          // Download/Open external
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'Deschide în aplicație externă',
          ),
          
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'external':
                  _openInExternalViewer();
                  break;
                case 'reload':
                  _loadPdf();
                  break;
                case 'info':
                  _showPdfInfo();
                  break;
                case 'toggle_mode':
                  _toggleViewMode();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 20),
                    SizedBox(width: 8),
                    Text('Deschide în aplicație externă'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'toggle_mode',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 20),
                    SizedBox(width: 8),
                    Text('Deschide în browser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reîncarcă'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Informații PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildMobileBody(),
    );
  }

  Widget _buildMobileBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Se încarcă PDF-ul...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Eroare la încărcarea PDF-ului',
              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadPdf,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reîncearcă'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _openInExternalViewer,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Deschide extern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile PDF viewer using flutter_pdfview
    if (_pdfFilePath != null) {
      return Stack(
        children: [
          PDFView(
            filePath: _pdfFilePath!,
            onViewCreated: (PDFViewController controller) {
              _pdfViewController = controller;
            },
            onPageChanged: _onPageChanged,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onError: (error) {
              print('PDF View Error: $error');
              setState(() {
                _hasError = true;
                _errorMessage = 'Eroare la afișarea PDF-ului: $error';
              });
            },
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'jumpToPage',
              backgroundColor: Colors.blue,
              onPressed: _showJumpToPageDialog,
              tooltip: 'Sari la pagină',
              child: const Icon(Icons.input),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF-ul nu a putut fi încărcat',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openInExternalViewer,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Deschide în aplicație externă'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _toggleViewMode() {
    // Switch from in-app to browser view
    _openInExternalViewer();
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informații PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titlu: ${widget.title}'),
            const SizedBox(height: 8),
            Text('URL: ${widget.pdfUrl}'),
            const SizedBox(height: 8),
            Text('Platformă: ${_isMobile ? 'Mobile (în aplicație)' : 'Web (browser)'}'),
            if (_isMobile) ...[
              const SizedBox(height: 8),
              Text('Pagini: $_totalPages'),
              const SizedBox(height: 8),
              Text('Pagina curentă: $_currentPage'),
              const SizedBox(height: 8),
              Text('Zoom: ${(_zoom * 100).toInt()}%'),
            ],
            if (_pdfBytes != null) ...[
              const SizedBox(height: 8),
              Text('Dimensiune: ${(_pdfBytes!.length / 1024).toStringAsFixed(1)} KB'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Închide'),
          ),
        ],
      ),
    );
  }

  void _showJumpToPageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sari la pagină'),
          content: TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Număr pagină',
              hintText: 'Introdu numărul paginii',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pageController.clear();
              },
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = _pageController.text.trim();
                final page = int.tryParse(text);
                if (page != null && page > 0 && page <= _totalPages) {
                  Navigator.pop(context);
                  _pageController.clear();
                  if (_pdfViewController != null) {
                    await _pdfViewController!.setPage(page - 1); // 0-based index
                  }
                } else {
                  // Show error
                  NotificationService.showError(
                    context: context,
                    message: 'Număr de pagină invalid',
                  );
                }
              },
              child: const Text('Sari'),
            ),
          ],
        );
      },
    );
  }
} 