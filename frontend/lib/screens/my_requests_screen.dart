import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
        title: const Text('Cererile mele'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Înapoi',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadRequests,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reîncearcă'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nu aveți cereri de împrumut',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final book = request['book'];
                          final requestDate = request['request_date'] != null
                              ? DateTime.parse(request['request_date'])
                                  .toLocal()
                              : null;
                          final dueDate = request['due_date'] != null
                              ? DateTime.parse(request['due_date']).toLocal()
                              : null;

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Book cover
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 100,
                                              height: 150,
                                              child: book['thumbnail_url'] !=
                                                      null
                                                  ? Image.network(
                                                      book['thumbnail_url'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Center(
                                                            child: Icon(Icons
                                                                .image_not_supported),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(Icons
                                                            .image_not_supported),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.book_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            book['name'] ??
                                                                'Carte necunoscută',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          Text(
                                                            book['author'] ??
                                                                '',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                          0.6),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Data cererii',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          Text(
                                                            requestDate != null
                                                                ? requestDate.toString().split(' ')[0]
                                                                : 'N/A',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                          0.6),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.event_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            _getDueDateLabel(request['status']),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          Text(
                                                            dueDate != null
                                                                ? dueDate.toString().split(' ')[0]
                                                                : 'N/A',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                          0.6),
                                                                ),
                                                          ),
                                                          if (dueDate != null && _isEstimatedDueDate(request['status'])) ...[
                                                            Text(
                                                              '(se va actualiza la ridicare)',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.4),
                                                                    fontStyle: FontStyle.italic,
                                                                  ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            request['status'])
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                          request['status']),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(
                                                        request['status']),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: _getStatusColor(
                                                          request['status']),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (request['status'] == 'IMPRUMUTAT') ...[
                                                  const SizedBox(height: 16),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showExtensionDialog(context, request),
                                                    icon: const Icon(Icons.calendar_today_rounded),
                                                    label: const Text('Solicită prelungire'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
        return 'Necunoscut';
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cererea de prelungire a fost trimisă cu succes!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadRequests(); // Refresh the list
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Eroare la trimiterea cererii: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
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
}
