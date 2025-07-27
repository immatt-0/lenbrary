import 'package:flutter/material.dart';
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
          message: 'Eroare la încărcarea notificărilor: \\${e.toString()}',
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
          message: 'Eroare la marcarea notificării ca citită: \\${e.toString()}',
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
          message: 'Toate notificările au fost marcate ca citite',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context: context,
          message: 'Eroare la marcarea notificărilor ca citite: \\${e.toString()}',
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
              'Data: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: ResponsiveTextStyles.getResponsiveTextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ResponsiveButton(
            text: 'Închide',
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }
  
  String _getNotificationTitle(String type) {
    switch (type) {
      case 'book_request':
        return 'Cerere de împrumut';
      case 'book_accepted':
        return 'Carte acceptată';
      case 'book_rejected':
        return 'Carte respinsă';
      case 'book_returned':
        return 'Carte returnată';
      case 'teacher_registered':
        return 'Profesor înregistrat';
      case 'message':
        return 'Mesaj nou';
      default:
        return 'Notificare';
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
                'Notificări',
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
            tooltip: 'Înapoi',
          ),
        ),
        actions: [
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
              tooltip: 'Marchează toate ca citite',
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
                        'Se încarcă notificările...',
                        style: ResponsiveTextStyles.getResponsiveTitleStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _notificationService.notifications.isEmpty
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
                                  Icons.notifications_none_rounded,
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
                            'Nu ai notificări',
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
                            'Toate notificările tale vor apărea aici',
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
                        itemCount: _notificationService.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notificationService.notifications[index];
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
                            isRead ? 'Citită' : 'Nouă',
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
    if (timestamp == null) return 'Acum';
    
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Acum';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m în urmă';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h în urmă';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}z în urmă';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Acum';
    }
  }
} 