import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
  final NotificationService _notificationService = NotificationService();
  
  // Filter state
  String _selectedFilter = 'all';
  
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
    _loadNotifications();
    
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
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  Future<void> _loadNotifications() async {
    try {
      await _notificationService.loadNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context: context,
          message: AppLocalizations.of(context)!.notificationLoadError(e.toString()),
        );
      }
    }
  }
  
  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context: context,
          message: AppLocalizations.of(context)!.markAsReadError(e.toString()),
        );
      }
    }
  }
  
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) setState(() {});
      if (mounted) {
        NotificationService.showSuccess(
          context: context,
          message: AppLocalizations.of(context)!.allNotificationsMarkedAsRead,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context: context,
          message: AppLocalizations.of(context)!.markAllAsReadError(e.toString()),
        );
      }
    }
  }
  
  void _showNotificationDetails(Map<String, dynamic> notification) {
    if (!mounted) return;
    
    // Mark as read if not already
    if (notification['is_read'] == false) {
      _markAsRead(notification['id']);
    }
    
    final timestamp = DateTime.parse(notification['timestamp'] ?? DateTime.now().toIso8601String()).toLocal();
    final type = notification['type'] as String? ?? 'unknown';
    final content = notification['content'] as String? ?? 'No content available';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _notificationService.getNotificationIcon(type),
              color: _notificationService.getNotificationColor(type),
              size: getResponsiveIconSize(24),
            ),
            SizedBox(width: getResponsiveSpacing(8)),
            Expanded(
              child: Text(
                _getNotificationTitle(type),
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: ResponsiveTextStyles.getResponsiveBodyStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: getResponsiveSpacing(16)),
            Text(
              AppLocalizations.of(context)!.date + ' ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: ResponsiveTextStyles.getResponsiveTextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ResponsiveButton(
            text: AppLocalizations.of(context)!.close,
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }
  
  String _getNotificationTitle(String type) {
    switch (type) {
      case 'book_requested':
        return AppLocalizations.of(context)!.bookRequested;
      case 'book_accepted':
        return AppLocalizations.of(context)!.bookAccepted;
      case 'book_rejected':
        return AppLocalizations.of(context)!.bookRejected;
      case 'book_returned':
        return AppLocalizations.of(context)!.bookReturned;
      case 'extension_requested':
        return AppLocalizations.of(context)!.extensionRequested;
      case 'extension_approved':
        return AppLocalizations.of(context)!.extensionApproved;
      case 'extension_rejected':
        return AppLocalizations.of(context)!.extensionRejected;
      case 'request_cancelled':
        return AppLocalizations.of(context)!.requestCancelled;
      case 'request_approved':
        return AppLocalizations.of(context)!.requestApproved;
      case 'teacher_registered':
        return AppLocalizations.of(context)!.teacherRegistered;
      case 'book_added':
        return AppLocalizations.of(context)!.bookAdded;
      case 'book_deleted':
        return AppLocalizations.of(context)!.bookDeleted;
      case 'book_updated':
        return AppLocalizations.of(context)!.bookUpdated;
      case 'message':
        return AppLocalizations.of(context)!.newMessage;
      case 'unknown':
        return AppLocalizations.of(context)!.unknownNotification;
      default:
        return AppLocalizations.of(context)!.notificationWithType(type);
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
        title: FadeTransition(
          opacity: _fadeAnimation,
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
                  borderRadius: getResponsiveBorderRadius(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: getResponsiveSpacing(8),
                      offset: Offset(0, getResponsiveSpacing(2)),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                AppLocalizations.of(context)!.notifications,
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(10),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: getResponsiveIconSize(20),
              ),
            ),
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _getFilterOptions().map((option) {
                return PopupMenuItem<String>(
                  value: option['value'],
                  child: Row(
                    children: [
                      Icon(
                        _selectedFilter == option['value'] 
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primary,
                        size: getResponsiveIconSize(18),
                      ),
                      SizedBox(width: getResponsiveSpacing(8)),
                      Text(
                        option['label']!,
                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                          fontSize: 14,
                          fontWeight: _selectedFilter == option['value'] 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            tooltip: AppLocalizations.of(context)!.filterNotifications,
          ),
          if (_notificationService.notifications.isNotEmpty)
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(getResponsiveSpacing(8)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: getResponsiveBorderRadius(10),
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: getResponsiveIconSize(20),
                ),
              ),
              onPressed: _markAllAsRead,
              tooltip: AppLocalizations.of(context)!.markAllAsRead,
            ),
        ],
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
        child: Column(
          children: [
            // Filter indicator
            if (_notificationService.notifications.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: getResponsiveSpacing(16),
                  vertical: getResponsiveSpacing(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: getResponsiveSpacing(16),
                  vertical: getResponsiveSpacing(12),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  borderRadius: getResponsiveBorderRadius(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: getResponsiveIconSize(18),
                    ),
                    SizedBox(width: getResponsiveSpacing(8)),
                    Expanded(
                      child: Text(
                        _selectedFilter == 'all' 
                            ? AppLocalizations.of(context)!.showingAllNotifications(_getFilteredNotifications().length)
                            : AppLocalizations.of(context)!.activeFilter(_getFilterOptions().firstWhere((o) => o['value'] == _selectedFilter)['label']!, _getFilteredNotifications().length),
                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (_selectedFilter != 'all')
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(getResponsiveSpacing(4)),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: getResponsiveBorderRadius(6),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: getResponsiveIconSize(16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Notifications content
            Expanded(
              child: _notificationService.isLoading
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
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        AppLocalizations.of(context)!.loadingNotifications,
                        style: ResponsiveTextStyles.getResponsiveTitleStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _getFilteredNotifications().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
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
                                child: Icon(
                                  _selectedFilter == 'all' 
                                      ? Icons.notifications_none_rounded 
                                      : Icons.filter_list_off_rounded,
                                  size: getResponsiveIconSize(48),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: getResponsiveSpacing(16)),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            _selectedFilter == 'all' 
                                ? AppLocalizations.of(context)!.noNotifications
                                : AppLocalizations.of(context)!.noNotificationsOfType,
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: getResponsiveSpacing(8)),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            _selectedFilter == 'all' 
                                ? AppLocalizations.of(context)!.allNotificationsWillAppear
                                : AppLocalizations.of(context)!.tryChangingFilter,
                            style: ResponsiveTextStyles.getResponsiveBodyStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        padding: getResponsivePadding(all: 16.0),
                        itemCount: _getFilteredNotifications().length,
                        itemBuilder: (context, index) {
                          final filteredNotifications = _getFilteredNotifications();
                          final notification = filteredNotifications[index];
                          final isRead = notification['is_read'] ?? false;
                          final type = notification['type'] as String? ?? 'unknown';
                          final content = notification['content'] as String? ?? 'No content available';
                          
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, getResponsiveSpacing(20) * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: _buildNotificationCard(notification, isRead, type, content),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isRead, String type, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveSpacing(12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRead 
              ? [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.8)]
              : [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: getResponsiveBorderRadius(16),
        boxShadow: [
          BoxShadow(
            color: isRead 
                ? Theme.of(context).colorScheme.shadow.withOpacity(0.05)
                : Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: isRead ? getResponsiveSpacing(8) : getResponsiveSpacing(12),
            offset: Offset(0, getResponsiveSpacing(4)),
            spreadRadius: isRead ? 0 : 2,
          ),
        ],
        border: Border.all(
          color: isRead 
              ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        borderRadius: getResponsiveBorderRadius(16),
        onTap: () => _showNotificationDetails(notification),
        child: Padding(
          padding: getResponsivePadding(all: 16),
          child: Row(
            children: [
              // Notification icon
              Container(
                padding: EdgeInsets.all(getResponsiveSpacing(12)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _notificationService.getNotificationColor(type).withOpacity(0.15),
                      _notificationService.getNotificationColor(type).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: getResponsiveBorderRadius(12),
                ),
                child: Icon(
                  _notificationService.getNotificationIcon(type),
                  color: _notificationService.getNotificationColor(type),
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(16)),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getNotificationTitle(type),
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              color: isRead ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: getResponsiveSpacing(12),
                            height: getResponsiveSpacing(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: getResponsiveSpacing(4),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: getResponsiveSpacing(4)),
                    Text(
                      content,
                      style: ResponsiveTextStyles.getResponsiveBodyStyle(
                        fontSize: 14,
                        color: isRead ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: getResponsiveSpacing(8)),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: getResponsiveIconSize(14),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(width: getResponsiveSpacing(4)),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getResponsiveSpacing(8), 
                            vertical: getResponsiveSpacing(4)
                          ),
                          decoration: BoxDecoration(
                            color: isRead 
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: getResponsiveBorderRadius(8),
                          ),
                          child: Text(
                            isRead ? AppLocalizations.of(context)!.read : AppLocalizations.of(context)!.newNotification,
                            style: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 10,
                              color: isRead 
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: getResponsiveSpacing(8)),
              // Arrow icon
              Container(
                padding: EdgeInsets.all(getResponsiveSpacing(8)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: getResponsiveBorderRadius(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: getResponsiveIconSize(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return AppLocalizations.of(context)!.now;
    
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return AppLocalizations.of(context)!.now;
      } else if (difference.inMinutes < 60) {
        return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
      } else if (difference.inHours < 24) {
        return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
      } else if (difference.inDays < 7) {
        return AppLocalizations.of(context)!.daysAgo(difference.inDays);
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return AppLocalizations.of(context)!.now;
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedFilter == 'all') {
      return _notificationService.notifications;
    }
    
    return _notificationService.notifications.where((notification) {
      final type = notification['type'] as String? ?? 'unknown';
      // Return notifications that exactly match the selected filter type
      return type == _selectedFilter;
    }).toList();
  }

  List<Map<String, String>> _getFilterOptions() {
    // Get unique notification types from current notifications
    final types = _notificationService.notifications
        .map((n) => n['type'] as String? ?? 'unknown')
        .toSet()
        .toList();
    
    List<Map<String, String>> options = [
      {'value': 'all', 'label': AppLocalizations.of(context)!.allNotifications},
    ];
    
    // Define the preferred order for notification types
    final preferredOrder = [
      'teacher_registered',
      'book_request',
      'book_requested',
      'book_accepted',
      'book_rejected', 
      'book_returned',
      'book_extension_request',
      'book_extension_approved',
      'book_extension_rejected',
      'extension_requested',
      'extension_approved',
      'extension_rejected',
      'request_cancelled',
      'request_approved',
      'book_added',
      'book_modified',
      'book_updated',
      'book_deleted',
      'message',
    ];
    
    // Add filters in the preferred order if they exist in current notifications
    for (String type in preferredOrder) {
      if (types.contains(type)) {
        switch (type) {
          case 'teacher_registered':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.registeredTeachers});
            break;
          case 'book_requested':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.bookRequests});
            break;
          case 'book_accepted':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.acceptedBooks});
            break;
          case 'book_rejected':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.rejectedBooks});
            break;
          case 'book_returned':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.returnedBooks});
            break;
          case 'book_extension_request':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.extensionRequests});
            break;
          case 'book_extension_approved':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.approvedExtensions});
            break;
          case 'book_extension_rejected':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.rejectedExtensions});
            break;
          case 'extension_requested':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.extensionRequests});
            break;
          case 'extension_approved':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.approvedExtensions});
            break;
          case 'extension_rejected':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.rejectedExtensions});
            break;
          case 'request_cancelled':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.cancelledRequests});
            break;
          case 'request_approved':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.approvedRequests});
            break;
          case 'book_added':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.addedBooks});
            break;
          case 'book_modified':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.updatedBooks});
            break;
          case 'book_updated':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.updatedBooks});
            break;
          case 'book_deleted':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.deletedBooks});
            break;
          case 'message':
            options.add({'value': type, 'label': AppLocalizations.of(context)!.messages});
            break;
        }
      }
    }
    
    // Add any remaining types that weren't in the preferred order
    for (String type in types) {
      if (!preferredOrder.contains(type) && type != 'unknown') {
        options.add({'value': type, 'label': AppLocalizations.of(context)!.otherNotifications});
      }
    }
    
    // Only add "Alte notificări" option if there are actually unknown types
    if (types.contains('unknown')) {
      options.add({'value': 'unknown', 'label': AppLocalizations.of(context)!.otherNotifications});
    }
    
    return options;
  }
} 