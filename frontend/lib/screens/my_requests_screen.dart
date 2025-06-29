import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> 
    with TickerProviderStateMixin, ResponsiveWidget {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await ApiService.getMyRequests();
      setState(() {
        _requests = requests;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                Icons.book_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: getResponsiveIconSize(24),
              ),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
            Text(
              'Cererile mele',
              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.all(getResponsiveSpacing(20)),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: getResponsiveSpacing(24)),
                    Text(
                      'Se încarcă cererile...',
                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(getResponsiveSpacing(20)),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: getResponsiveIconSize(48),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: getResponsiveSpacing(16)),
                        Text(
                          _errorMessage!,
                          style: ResponsiveTextStyles.getResponsiveTitleStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: getResponsiveSpacing(16)),
                        ResponsiveButton(
                          text: 'Reîncearcă',
                          onPressed: _loadRequests,
                          icon: Icons.refresh_rounded,
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: EdgeInsets.all(getResponsiveSpacing(24)),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inbox_rounded,
                                      size: getResponsiveIconSize(56),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(24)),
                            Text(
                              'Nu aveți cereri de împrumut',
                              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: getResponsiveSpacing(16)),
                            Text(
                              'Cererile tale vor apărea aici după ce vei solicita cărți',
                              style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: getResponsivePadding(horizontal: 8, vertical: 4),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 500 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, getResponsiveSpacing(30) * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: _buildRequestCard(request),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_ASTEPTARE':
        return Colors.orange;
      case 'APROBAT':
        return Colors.blue;
      case 'GATA_RIDICARE':
        return Colors.purple;
      case 'IMPRUMUTAT':
        return Colors.green;
      case 'RETURNAT':
        return Colors.grey;
      case 'INTARZIAT':
        return Colors.red;
      case 'RESPINS':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'IN_ASTEPTARE':
        return 'În așteptare';
      case 'APROBAT':
        return 'Aprobată';
      case 'GATA_RIDICARE':
        return 'Gata de ridicare';
      case 'IMPRUMUTAT':
        return 'Împrumutată';
      case 'RETURNAT':
        return 'Returnată';
      case 'INTARZIAT':
        return 'Întârziată';
      case 'RESPINS':
        return 'Respinsă';
      case 'ANULATA':
        return 'Anulată';
      default:
        return 'Necunoscut';
    }
  }

  String _getDueDateLabel(String status) {
    switch (status) {
      case 'IN_ASTEPTARE':
        return 'Data estimată';
      case 'APROBAT':
        return 'Data estimată';
      case 'GATA_RIDICARE':
        return 'Data estimată';
      case 'IMPRUMUTAT':
        return 'Data returnării';
      case 'RETURNAT':
        return 'Data returnării';
      case 'INTARZIAT':
        return 'Data returnării';
      case 'RESPINS':
        return 'Data returnării';
      default:
        return 'Data';
    }
  }

  String _getFullDueDateLabel(String status) {
    switch (status) {
      case 'IN_ASTEPTARE':
        return 'Data returnării estimată';
      case 'APROBAT':
        return 'Data returnării estimată';
      case 'GATA_RIDICARE':
        return 'Data returnării estimată';
      case 'IMPRUMUTAT':
        return 'Data returnării';
      case 'RETURNAT':
        return 'Data returnării';
      case 'INTARZIAT':
        return 'Data returnării';
      case 'RESPINS':
        return 'Data returnării';
      default:
        return 'Data';
    }
  }

  Future<void> _showExtensionDialog(BuildContext context, Map<String, dynamic> request) async {
    int selectedDays = 7; // Default extension period
    final TextEditingController messageController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Solicită prelungire împrumut'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carte: ${request['book']['name']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                const Text('Perioada de prelungire:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDays,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [7, 14, 21, 30].map((days) {
                    return DropdownMenuItem<int>(
                      value: days,
                      child: Text('$days zile'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedDays = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Mesaj (opțional):'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Adaugă un mesaj pentru bibliotecar...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.requestLoanExtension(
                    borrowingId: request['id'],
                    requestedDays: selectedDays,
                    message: messageController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    NotificationService.showSuccess(
                      context: context,
                      message: 'Cererea de prelungire a fost trimisă cu succes!',
                    );
                    await _loadRequests(); // Refresh the list
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    NotificationService.showError(
                      context: context,
                      message: 'Eroare la trimiterea cererii: ${e.toString()}',
                    );
                  }
                }
              },
              child: const Text('Trimite cererea'),
            ),
          ],
        );
      },
    );
  }

  bool _isEstimatedDueDate(String status) {
    return status == 'IN_ASTEPTARE' || status == 'APROBAT' || status == 'GATA_RIDICARE';
  }

  bool _isAlreadyExtended(Map request) {
    return request['has_been_extended'] == true;
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final book = request['book'] ?? {};
    final status = request['status']?.toString() ?? 'Necunoscut';
    final bookType = book['type']?.toString() ?? '';
    final bookName = book['name']?.toString() ?? 'Carte necunoscută';
    final bookAuthor = book['author']?.toString() ?? 'Autor necunoscut';
    final thumbnailRaw = book['thumbnail_url']?.toString();
    final requestDateStr = request['request_date']?.toString();
    final dueDateStr = request['due_date']?.toString();

    DateTime? requestDate;
    DateTime? dueDate;
    try {
      if (requestDateStr != null && requestDateStr.isNotEmpty) {
        requestDate = DateTime.tryParse(requestDateStr);
      }
      if (dueDateStr != null && dueDateStr.isNotEmpty) {
        dueDate = DateTime.tryParse(dueDateStr);
      }
    } catch (e) {
      // ignore parse errors
    }

    // Build correct thumbnail URL (same logic as search_books_screen)
    final thumbnailUrl = (thumbnailRaw != null && thumbnailRaw.isNotEmpty)
        ? (thumbnailRaw.startsWith('http')
            ? thumbnailRaw
            : ApiService.baseUrl + '/media/' + thumbnailRaw.replaceAll(RegExp(r'^/?media/'), ''))
        : null;

    // Medium size: between original and very large
    final thumbnailWidth = ResponsiveService.getSpacing(48);
    final thumbnailHeight = ResponsiveService.getSpacing(64);
    final borderRadius = ResponsiveService.getSpacing(14);
    final cardPadding = ResponsiveService.getSpacing(16);

    // Debug print for requests with missing/invalid fields
    if (request['status'] == null || book['name'] == null || book['author'] == null) {
      // ignore: avoid_print
      print('[DEBUG] Invalid request data: $request');
    }

    return GestureDetector(
      onTap: status == 'IMPRUMUTAT'
          ? () {
              if (_isAlreadyExtended(request)) {
                NotificationService.showWarning(
                  context: context,
                  message: 'Această carte a fost deja prelungită o dată și nu mai poate fi prelungită.',
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExtendLoanScreen(request: request),
                ),
              ).then((value) {
                if (value == true) _loadRequests();
              });
            }
          : null,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveService.getSpacing(10),
          vertical: ResponsiveService.getSpacing(8),
        ),
        child: Card(
          elevation: 7,
          shadowColor: Colors.black.withOpacity(0.11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail 4:3
                  Builder(
                    builder: (context) {
                      if (thumbnailUrl == null) {
                        return Container(
                          width: thumbnailWidth,
                          height: thumbnailHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          ),
                          child: Icon(
                            bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Image.network(
                          thumbnailUrl,
                          width: thumbnailWidth,
                          height: thumbnailHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: thumbnailWidth,
                              height: thumbnailHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(borderRadius),
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              ),
                              child: Icon(
                                bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                size: 28,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 14),
                  // Book Info and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookName,
                          style: ResponsiveTextStyles.getResponsiveTitleStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Text(
                          bookAuthor,
                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.11),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: _getStatusColor(status).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 15,
                              ),
                              SizedBox(width: 7),
                              Text(
                                _getStatusText(status),
                                style: ResponsiveTextStyles.getResponsiveTextStyle(
                                  fontSize: 13,
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        // Dates Section
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.blue),
                            SizedBox(width: 5),
                            Text(
                              'Cerere: ',
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              requestDate != null ? '${requestDate.day}/${requestDate.month}/${requestDate.year}' : 'N/A',
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.event_available_rounded, size: 13, color: Colors.green),
                            SizedBox(width: 5),
                            Text(
                              'Scadență: ',
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dueDate != null ? '${dueDate.day}/${dueDate.month}/${dueDate.year}' : 'N/A',
                              style: ResponsiveTextStyles.getResponsiveTextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        // Cancel button for IN_ASTEPTARE and APROBAT
                        if (status == 'IN_ASTEPTARE' || status == 'APROBAT') ...[
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[700], size: 22),
                                tooltip: 'Anulează cererea',
                                onPressed: () => _showCancelDialog(context, request),
                              ),
                            ],
                          ),
                        ],
                      ],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'IN_ASTEPTARE':
        return Icons.schedule_rounded;
      case 'APROBAT':
        return Icons.check_circle_rounded;
      case 'GATA_RIDICARE':
        return Icons.local_shipping_rounded;
      case 'IMPRUMUTAT':
        return Icons.book_rounded;
      case 'RETURNAT':
        return Icons.check_circle_rounded;
      case 'RESPINS':
        return Icons.close_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  void _showCancelDialog(BuildContext context, Map request) {
    final TextEditingController _cancelMessageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red[700]),
              SizedBox(width: 8),
              Text('Anulează cererea', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sigur vrei să anulezi această cerere?'),
              SizedBox(height: 16),
              Text('Mesaj pentru bibliotecar (opțional):'),
              SizedBox(height: 8),
              TextField(
                controller: _cancelMessageController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Adaugă un mesaj...'
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Renunță'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.delete_outline_rounded),
              label: Text('Anulează'),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ApiService.cancelRequest(
                    requestId: request['id'],
                    message: _cancelMessageController.text.trim(),
                  );
                  if (mounted) {
                    NotificationService.showSuccess(
                      context: context,
                      message: 'Cererea a fost anulată cu succes.',
                    );
                    await _loadRequests();
                  }
                } catch (e) {
                  if (mounted) {
                    NotificationService.showError(
                      context: context,
                      message: 'Eroare la anulare: ${e.toString()}',
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class ExtendLoanScreen extends StatefulWidget {
  final Map request;
  const ExtendLoanScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<ExtendLoanScreen> createState() => _ExtendLoanScreenState();
}

class _ExtendLoanScreenState extends State<ExtendLoanScreen> with ResponsiveWidget {
  int _selectedDays = 7;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitExtension() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.requestLoanExtension(
        borrowingId: widget.request['id'],
        requestedDays: _selectedDays,
        message: _messageController.text.trim(),
      );
      if (mounted) {
        NotificationService.showSuccess(
          context: context,
          message: 'Cererea de prelungire a fost trimisă cu succes!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      String msg = e.toString();
      final match = RegExp(r'\{"error":"([^"]+)"\}').firstMatch(msg);
      if (match != null) {
        msg = match.group(1)!;
      }
      if (mounted) {
        if (msg.toLowerCase().contains('already extended')) {
          NotificationService.showWarning(
            context: context,
            message: 'Această carte a fost deja prelungită o dată și nu mai poate fi prelungită.',
          );
        } else {
          NotificationService.showError(
            context: context,
            message: msg,
          );
        }
      }
      // If the error is about already extended, pop back
      if (msg.toLowerCase().contains('already extended')) {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    final book = widget.request['book'] ?? {};
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                Icons.schedule_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: getResponsiveIconSize(24),
              ),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
            Text(
              'Prelungire împrumut',
              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
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
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(getResponsiveSpacing(18)),
              ),
              margin: EdgeInsets.symmetric(
                horizontal: getResponsiveSpacing(16),
                vertical: getResponsiveSpacing(24),
              ),
              child: Padding(
                padding: EdgeInsets.all(getResponsiveSpacing(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(getResponsiveSpacing(10)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(getResponsiveSpacing(10)),
                          ),
                          child: Icon(
                            Icons.book_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: getResponsiveIconSize(22),
                          ),
                        ),
                        SizedBox(width: getResponsiveSpacing(12)),
                        Expanded(
                          child: Text(
                            book['name'] ?? 'Carte necunoscută',
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getResponsiveSpacing(20)),
                    Text(
                      'Perioada de prelungire:',
                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: getResponsiveSpacing(8)),
                    DropdownButtonFormField<int>(
                      value: _selectedDays,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getResponsiveSpacing(10)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: getResponsiveSpacing(16),
                          vertical: getResponsiveSpacing(12),
                        ),
                      ),
                      items: [7, 14, 21, 30].map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Text('$days zile', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 15)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedDays = value);
                        }
                      },
                    ),
                    SizedBox(height: getResponsiveSpacing(20)),
                    Text(
                      'Mesaj (opțional):',
                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: getResponsiveSpacing(8)),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getResponsiveSpacing(10)),
                        ),
                        hintText: 'Adaugă un mesaj pentru bibliotecar...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: getResponsiveSpacing(16),
                          vertical: getResponsiveSpacing(12),
                        ),
                      ),
                      maxLines: 3,
                      style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 15),
                    ),
                    SizedBox(height: getResponsiveSpacing(24)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitExtension,
                        icon: _isLoading
                            ? SizedBox(
                                width: getResponsiveSpacing(20),
                                height: getResponsiveSpacing(20),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.send_rounded, size: getResponsiveIconSize(20)),
                        label: Text(
                          'Trimite cererea',
                          style: ResponsiveTextStyles.getResponsiveTitleStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: getResponsiveSpacing(14)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(getResponsiveSpacing(12)),
                          ),
                          elevation: 4,
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
    );
  }
}
