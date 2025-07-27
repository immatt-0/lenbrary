import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';

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
          margin: EdgeInsets.only(left: getResponsiveSpacing(20), top: getResponsiveSpacing(8), bottom: getResponsiveSpacing(8)),
          padding: EdgeInsets.all(getResponsiveSpacing(2)),
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.surface,
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

  bool _isEstimatedDueDate(String status) {
    return status == 'IN_ASTEPTARE' || status == 'APROBAT' || status == 'GATA_RIDICARE';
  }

  bool _isAlreadyExtended(Map request) {
    return request['has_been_extended'] == true;
  }

  DateTime? _calculateExpectedDueDate(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? '';
    final dueDateStr = request['due_date']?.toString();
    final requestDateStr = request['request_date']?.toString();
    final loanDurationDays = request['loan_duration_days'] ?? 14; // Default to 14 days

    // For waiting, approved, or ready for pickup status, calculate expected due date
    if (_isEstimatedDueDate(status)) {
      DateTime? baseDate;
      
      // Try to use request date as base
      if (requestDateStr != null && requestDateStr.isNotEmpty) {
        baseDate = DateTime.tryParse(requestDateStr);
      }
      
      // If no request date, use current date
      baseDate ??= DateTime.now();
      
      // Calculate expected due date by adding loan duration to base date
      return baseDate.add(Duration(days: loanDurationDays));
    }
    
    // For other statuses, use the actual due date from database
    if (dueDateStr != null && dueDateStr.isNotEmpty) {
      return DateTime.tryParse(dueDateStr);
    }
    
    return null;
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final book = request['book'] ?? {};
    final status = request['status']?.toString() ?? 'Necunoscut';
    final bookType = book['type']?.toString() ?? '';
    final bookName = book['name']?.toString() ?? 'Carte necunoscută';
    final bookAuthor = book['author']?.toString() ?? 'Autor necunoscut';
    final thumbnailRaw = book['thumbnail_url']?.toString();
    final requestDateStr = request['request_date']?.toString();

    DateTime? requestDate;
    DateTime? dueDate;
    try {
      if (requestDateStr != null && requestDateStr.isNotEmpty) {
        requestDate = DateTime.tryParse(requestDateStr);
      }
      // Use the new calculation method for due date
      dueDate = _calculateExpectedDueDate(request);
    } catch (e) {
      // ignore parse errors
    }

    // Build correct thumbnail URL (same logic as search_books_screen)
    final thumbnailUrl = (thumbnailRaw != null && thumbnailRaw.isNotEmpty)
        ? (thumbnailRaw.startsWith('http')
            ? thumbnailRaw
            : '${ApiService.baseUrl}/media/${thumbnailRaw.replaceAll(RegExp(r'^/?media/'), '')}')
        : null;

    // Enhanced sizing for more professional look
    final thumbnailWidth = ResponsiveService.getSpacing(56);
    final thumbnailHeight = ResponsiveService.getSpacing(76);
    final borderRadius = ResponsiveService.getSpacing(16);
    final cardPadding = ResponsiveService.getSpacing(18);

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
          horizontal: ResponsiveService.getSpacing(12),
          vertical: ResponsiveService.getSpacing(10),
        ),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.97),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Status indicator stripe on the left
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getStatusColor(status),
                          _getStatusColor(status).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        bottomLeft: Radius.circular(borderRadius),
                      ),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Thumbnail with shimmer effect
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderRadius - 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(borderRadius - 2),
                              child: thumbnailUrl == null
                                  ? Container(
                                      width: thumbnailWidth,
                                      height: thumbnailHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                            Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(borderRadius - 2),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                          size: ResponsiveService.getSpacing(32),
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : Image.network(
                                      thumbnailUrl,
                                      width: thumbnailWidth,
                                      height: thumbnailHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: thumbnailWidth,
                                          height: thumbnailHeight,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                                Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(borderRadius - 2),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              bookType == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                              size: ResponsiveService.getSpacing(32),
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          SizedBox(width: ResponsiveService.getSpacing(16)),
                          // Enhanced Book Info and Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Book Title with enhanced styling
                                Text(
                                  bookName,
                                  style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ResponsiveService.getSpacing(6)),
                                // Author with refined styling
                                Text(
                                  bookAuthor,
                                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: ResponsiveService.getSpacing(12)),
                                // Enhanced Status Badge with improved design
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveService.getSpacing(14),
                                    vertical: ResponsiveService.getSpacing(8),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getStatusColor(status).withOpacity(0.18),
                                        _getStatusColor(status).withOpacity(0.12),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(14)),
                                    border: Border.all(
                                      color: _getStatusColor(status).withOpacity(0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                        size: ResponsiveService.getSpacing(16),
                                      ),
                                      SizedBox(width: ResponsiveService.getSpacing(8)),
                                      Text(
                                        _getStatusText(status),
                                        style: ResponsiveTextStyles.getResponsiveTextStyle(
                                          fontSize: 14,
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Enhanced Dates Section with better layout
                      if (status != 'ANULATA' && status != 'RESPINS') ...[
                        SizedBox(height: ResponsiveService.getSpacing(16)),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: ResponsiveService.getSpacing(6)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveService.getSpacing(12),
                                  vertical: ResponsiveService.getSpacing(12),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.10),
                                      Colors.blue.withOpacity(0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue),
                                        SizedBox(width: ResponsiveService.getSpacing(6)),
                                        Text(
                                          'Cerere',
                                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveService.getSpacing(4)),
                                    Text(
                                      requestDate != null 
                                        ? '${requestDate.day.toString().padLeft(2, '0')}/${requestDate.month.toString().padLeft(2, '0')}/${requestDate.year}' 
                                        : 'N/A',
                                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: ResponsiveService.getSpacing(6)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveService.getSpacing(12),
                                  vertical: ResponsiveService.getSpacing(12),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (_isEstimatedDueDate(status) ? Colors.orange : Colors.green).withOpacity(0.10),
                                      (_isEstimatedDueDate(status) ? Colors.orange : Colors.green).withOpacity(0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
                                  border: Border.all(
                                    color: (_isEstimatedDueDate(status) ? Colors.orange : Colors.green).withOpacity(0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isEstimatedDueDate(status) ? Colors.orange : Colors.green).withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_available_rounded, 
                                          size: 16, 
                                          color: _isEstimatedDueDate(status) ? Colors.orange : Colors.green
                                        ),
                                        SizedBox(width: ResponsiveService.getSpacing(6)),
                                        Text(
                                          _isEstimatedDueDate(status) ? 'Estimat' : 'Scadență',
                                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                                            fontSize: 12,
                                            color: _isEstimatedDueDate(status) ? Colors.orange : Colors.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveService.getSpacing(4)),
                                    Text(
                                      dueDate != null 
                                        ? '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}' 
                                        : 'N/A',
                                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Extension hint for borrowed books
                      if (status == 'IMPRUMUTAT' && !_isAlreadyExtended(request)) ...[
                        SizedBox(height: ResponsiveService.getSpacing(12)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveService.getSpacing(12),
                            vertical: ResponsiveService.getSpacing(8),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                Theme.of(context).colorScheme.primary.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(10)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: ResponsiveService.getSpacing(16),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: ResponsiveService.getSpacing(6)),
                              Text(
                                'Apasă pentru prelungire',
                                style: ResponsiveTextStyles.getResponsiveTextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Enhanced action buttons positioned at top right
                if (status == 'IN_ASTEPTARE' || status == 'APROBAT')
                  Positioned(
                    top: ResponsiveService.getSpacing(12),
                    right: ResponsiveService.getSpacing(12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                        onTap: () => _showCancelDialog(context, request),
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveService.getSpacing(8)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.12),
                                Colors.red.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.red[700],
                            size: ResponsiveService.getSpacing(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (status == 'IMPRUMUTAT')
                  Positioned(
                    top: ResponsiveService.getSpacing(12),
                    right: ResponsiveService.getSpacing(12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                        onTap: () async {
                          if (_isAlreadyExtended(request)) {
                            NotificationService.showWarning(
                              context: context,
                              message: 'Această carte a fost deja prelungită o dată și nu mai poate fi prelungită.',
                            );
                            return;
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExtendLoanScreen(request: request),
                            ),
                          );
                          if (result == true) {
                            _loadRequests();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveService.getSpacing(8)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: ResponsiveService.getSpacing(20),
                          ),
                        ),
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
          // If the error is about already extended, pop back
          Navigator.pop(context, false);
        } else {
          NotificationService.showError(
            context: context,
            message: msg,
          );
        }
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
              Theme.of(context).colorScheme.surface,
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
                    // Book image and title section at the top center
                    Center(
                      child: Column(
                        children: [
                          // Book cover image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(getResponsiveSpacing(12)),
                            child: widget.request['book']['thumbnail_url'] != null
                                ? Image.network(
                                    widget.request['book']['thumbnail_url'].toString().startsWith('http')
                                        ? widget.request['book']['thumbnail_url']
                                        : ApiService.baseUrl + '/media/' + widget.request['book']['thumbnail_url'].toString().replaceAll(RegExp(r'^/?media/'), ''),
                                    width: getResponsiveSpacing(80),
                                    height: getResponsiveSpacing(110),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: getResponsiveSpacing(80),
                                        height: getResponsiveSpacing(110),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(getResponsiveSpacing(12)),
                                        ),
                                        child: Icon(
                                          Icons.book_rounded,
                                          size: getResponsiveIconSize(40),
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: getResponsiveSpacing(80),
                                    height: getResponsiveSpacing(110),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(getResponsiveSpacing(12)),
                                    ),
                                    child: Icon(
                                      Icons.book_rounded,
                                      size: getResponsiveIconSize(40),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                          SizedBox(height: getResponsiveSpacing(12)),
                          // Book title
                          Text(
                            book['name'] ?? 'Carte necunoscută',
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: getResponsiveSpacing(24)),
                    
                    SizedBox(height: getResponsiveSpacing(20)),
                    
                    // Current due date section
                    Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(16)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(getResponsiveSpacing(12)),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current due date
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                                size: getResponsiveIconSize(20),
                              ),
                              SizedBox(width: getResponsiveSpacing(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data curentă de returnare:',
                                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                    SizedBox(height: getResponsiveSpacing(4)),
                                    Text(
                                      widget.request['due_date'] != null 
                                        ? DateTime.parse(widget.request['due_date']).toLocal().toString().split(' ')[0]
                                        : 'Necunoscută',
                                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: getResponsiveSpacing(12)),
                          // Estimated new due date
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                color: Colors.green,
                                size: getResponsiveIconSize(20),
                              ),
                              SizedBox(width: getResponsiveSpacing(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimare nouă dată de returnare:',
                                      style: ResponsiveTextStyles.getResponsiveTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(height: getResponsiveSpacing(4)),
                                    Text(
                                      widget.request['due_date'] != null 
                                        ? DateTime.parse(widget.request['due_date'])
                                            .add(Duration(days: _selectedDays))
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0]
                                        : 'Necunoscută',
                                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade700,
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
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
