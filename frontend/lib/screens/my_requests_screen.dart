import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.book_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cererile mele',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
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
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
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
                            padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 24),
                    Text(
                      'Se încarcă cererile...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadRequests,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text(
                            'Reîncearcă',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
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
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inbox_rounded,
                                      size: 56,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Nu aveți cereri de împrumut',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cererile tale vor apărea aici după ce vei solicita cărți',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 500 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final book = request['book'];
    final requestDate = request['request_date'] != null
        ? DateTime.parse(request['request_date'])
            .toLocal()
        : null;
    final dueDate = request['due_date'] != null
        ? DateTime.parse(request['due_date']).toLocal()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Photo and Info Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Photo
                    Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: book['thumbnail_url'] != null
                            ? Image.network(
                                book['thumbnail_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      Icons.book_rounded,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.book_rounded,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Book Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['name'] ?? 'Carte necunoscută',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book['author'] ?? 'Autor necunoscut',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(request['status']).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(request['status']),
                                  color: _getStatusColor(request['status']),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(request['status']),
                                  style: TextStyle(
                                    color: _getStatusColor(request['status']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                const SizedBox(height: 20),
                // Dates Section
                Row(
                  children: [
                    // Request Date
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Data cererii',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              requestDate != null ? '${requestDate.day}/${requestDate.month}/${requestDate.year}' : 'N/A',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Due Date
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.event_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Tooltip(
                                    message: _getFullDueDateLabel(request['status']),
                                    child: Text(
                                      _getDueDateLabel(request['status']),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dueDate != null ? '${dueDate.day}/${dueDate.month}/${dueDate.year}' : 'N/A',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (dueDate != null && _isEstimatedDueDate(request['status'])) ...[
                              const SizedBox(height: 4),
                              Text(
                                '(se va actualiza la ridicare)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Extension Button (if borrowed)
                if (request['status'] == 'IMPRUMUTAT') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: request['has_been_extended'] == true 
                          ? null 
                          : () => _showExtensionDialog(context, request),
                        icon: Icon(
                          request['has_been_extended'] == true 
                            ? Icons.block_rounded 
                            : Icons.calendar_today_rounded
                        ),
                        label: Text(
                          request['has_been_extended'] == true 
                            ? 'Deja prelungit'
                            : 'Solicită prelungire',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: request['has_been_extended'] == true 
                            ? Colors.grey 
                            : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: request['has_been_extended'] == true ? 0 : 2,
                        ),
                      ),
                    ],
                  ),
                  if (request['has_been_extended'] == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Această carte a fost deja prelungită o dată',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
}
