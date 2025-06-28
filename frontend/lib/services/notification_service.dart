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
        return Icons.book;
      case 'book_accepted':
        return Icons.check_circle;
      case 'book_rejected':
        return Icons.cancel;
      case 'book_returned':
        return Icons.assignment_return;
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
        return Colors.orange;
      case 'book_accepted':
        return Colors.green;
      case 'book_rejected':
        return Colors.red;
      case 'book_returned':
        return Colors.blue;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 