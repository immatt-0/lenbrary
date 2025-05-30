import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    try {
      await _notificationService.loadNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcarea notificărilor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la marcarea notificării ca citită: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getNotificationTitle(type),
                style: const TextStyle(fontSize: 18),
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
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Data: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Închide'),
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
      case 'message':
        return 'Mesaj nou';
      default:
        return 'Notificare';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificări'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _notificationService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificationService.notifications.isEmpty
              ? const Center(child: Text('Nu ai notificări.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _notificationService.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notificationService.notifications[index];
                    final isRead = notification['is_read'] ?? false;
                    final type = notification['type'] as String? ?? 'unknown';
                    final content = notification['content'] as String? ?? 'No content available';
                    
                    return Card(
                      elevation: isRead ? 1 : 3,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      color: isRead ? null : Colors.blue.shade50,
                      child: ListTile(
                        leading: Icon(
                          _notificationService.getNotificationIcon(type),
                          color: _notificationService.getNotificationColor(type),
                        ),
                        title: Text(
                          _getNotificationTitle(type),
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () => _showNotificationDetails(notification),
                      ),
                    );
                  },
                ),
    );
  }
} 