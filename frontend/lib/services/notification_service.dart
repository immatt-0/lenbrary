import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // Get all notifications from the API
      final response = await ApiService.getNotifications();
      // Map backend fields to frontend fields
      _notifications = List<Map<String, dynamic>>.from(response).map((notification) {
        return {
          'id': notification['id'],
          'type': notification['type'] as String? ?? 'unknown',
          'content': notification['message'] as String? ?? 'No content available', // Map 'message' to 'content'
          'timestamp': notification['timestamp'] as String? ?? DateTime.now().toIso8601String(),
          'is_read': notification['is_read'] as bool? ?? false,
          'book': notification['book'],
          'borrowing': notification['borrowing'],
          'created_by': notification['created_by'],
        };
      }).toList();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      rethrow;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationRead(notificationId);
      // Update local state
      _notifications = _notifications.map((notification) {
        if (notification['id'] == notificationId) {
          return {...notification, 'is_read': true};
        }
        return notification;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      // Update local state - mark all notifications as read
      _notifications = _notifications.map((notification) {
        return {...notification, 'is_read': true};
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  int get unreadCount {
    return _notifications.where((n) => n['is_read'] == false).length;
  }

  // Helper method to get notification icon based on type
  IconData getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'book_request':
      case 'book_requested':
        return Icons.book_rounded; // Special icon for book requests
      case 'book_accepted':
        return Icons.check_circle;
      case 'book_rejected':
        return Icons.cancel;
      case 'book_returned':
        return Icons.assignment_return;
      case 'book_extension_request':
      case 'extension_requested':
        return Icons.extension_rounded; // Special icon for extension requests
      case 'book_extension_approved':
      case 'extension_approved':
        return Icons.schedule_send;
      case 'book_extension_rejected':
      case 'extension_rejected':
        return Icons.event_busy;
      case 'request_cancelled':
        return Icons.cancel_presentation;
      case 'request_approved':
        return Icons.check_circle_outline_rounded; // Special icon for approved requests
      case 'teacher_registered':
        return Icons.person_add;
      case 'book_added':
        return Icons.library_add;
      case 'book_deleted':
        return Icons.delete;
      case 'book_modified':
      case 'book_updated':
        return Icons.update_rounded; // Special icon for updated books
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

    // Helper method to get notification color based on type
  Color getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'book_request':
      case 'book_requested':
        return Colors.orange; // Orange for book requests
      case 'book_accepted':
        return Colors.green;
      case 'book_rejected':
        return Colors.red;
      case 'book_returned':
        return Colors.blue;
      case 'book_extension_request':
      case 'extension_requested':
        return Colors.amber; // Amber for extension requests
      case 'book_extension_approved':
      case 'extension_approved':
        return Colors.lightGreen;
      case 'book_extension_rejected':
      case 'extension_rejected':
        return Colors.deepOrange;
      case 'request_cancelled':
        return Colors.redAccent;
      case 'request_approved':
        return Colors.green; // Green for approved requests
      case 'teacher_registered':
        return Colors.teal;
      case 'book_added':
        return Colors.indigo;
      case 'book_deleted':
        return Colors.brown;
      case 'book_modified':
      case 'book_updated':
        return Colors.deepPurple; // Deep purple for book updates
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static void showTopNotification({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      overlayEntry.remove();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Convenience methods for common notification types
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: duration,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981), // Green
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFF59E0B), // Orange
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: Theme.of(context).colorScheme.primary,
      duration: duration,
    );
  }

  // Specific notification types for the app
  static void showFileUploadError({
    required BuildContext context,
    required String message,
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.file_upload_rounded,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  static void showValidationError({
    required BuildContext context,
    required String message,
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  static void showNetworkError({
    required BuildContext context,
    required String message,
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.wifi_off_rounded,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void showBookActionSuccess({
    required BuildContext context,
    required String message,
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.book_rounded,
      backgroundColor: const Color(0xFF10B981), // Green
    );
  }

  static void showExamActionSuccess({
    required BuildContext context,
    required String message,
  }) {
    showTopNotification(
      context: context,
      message: message,
      icon: Icons.quiz_rounded,
      backgroundColor: const Color(0xFF10B981), // Green
    );
  }
} 