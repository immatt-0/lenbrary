import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExtensionRequestsScreen extends StatefulWidget {
  const ExtensionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ExtensionRequestsScreen> createState() => _ExtensionRequestsScreenState();
}

class _ExtensionRequestsScreenState extends State<ExtensionRequestsScreen> {
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
      final loans = await ApiService.getActiveLoans();
      final requests = loans.where((loan) =>
        loan['student_message'] != null && loan['student_message'].toString().isNotEmpty
      ).toList();
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

  int? extractRequestedDays(String? message) {
    if (message == null) return null;
    final regex = RegExp(r'(\d+)\s*zile');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  DateTime? getCurrentDueDate(Map<dynamic, dynamic> loan) {
    final dueDateStr = loan['due_date'];
    if (dueDateStr != null) {
      try {
        return DateTime.parse(dueDateStr).toLocal();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  DateTime? getExtendedDueDate(Map<dynamic, dynamic> loan, int? requestedDays) {
    final currentDueDate = getCurrentDueDate(loan);
    if (currentDueDate != null && requestedDays != null) {
      return currentDueDate.add(Duration(days: requestedDays));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cereri de extindere'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
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
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadRequests,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reîncearcă'),
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('Nu există cereri de extindere', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final loan = _requests[index];
                          final student = loan['student']?['user'] ?? {};
                          final book = loan['book'] ?? {};
                          final studentMessage = loan['student_message']?.toString() ?? '';
                          final requestedDays = extractRequestedDays(studentMessage);
                          final currentDueDate = getCurrentDueDate(loan);
                          final extendedDueDate = getExtendedDueDate(loan, requestedDays);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExtensionRequestDetailScreen(loan: loan),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                toTitleCase('${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                              ),
                                              Text(student['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.book_rounded, color: Theme.of(context).colorScheme.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(book['name'] ?? 'Carte necunoscută', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                              Text(book['author'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.timer_rounded, color: Theme.of(context).colorScheme.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Zile solicitate', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                              Text(
                                                '${requestedDays ?? 'necunoscut'} zile',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              if (currentDueDate != null && extendedDueDate != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'De la: ${currentDueDate.toString().split(' ')[0]}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                                Text(
                                                  'Până la: ${extendedDueDate.toString().split(' ')[0]}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                          );
                        },
                      ),
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class ExtensionRequestDetailScreen extends StatelessWidget {
  final Map loan;
  const ExtensionRequestDetailScreen({Key? key, required this.loan}) : super(key: key);

  int? extractRequestedDays(String? message) {
    if (message == null) return null;
    final regex = RegExp(r'(\d+)\s*zile');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  DateTime? getCurrentDueDate(Map<dynamic, dynamic> loan) {
    final dueDateStr = loan['due_date'];
    if (dueDateStr != null) {
      try {
        return DateTime.parse(dueDateStr).toLocal();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  DateTime? getExtendedDueDate(Map<dynamic, dynamic> loan, int? requestedDays) {
    final currentDueDate = getCurrentDueDate(loan);
    if (currentDueDate != null && requestedDays != null) {
      return currentDueDate.add(Duration(days: requestedDays));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final student = loan['student']?['user'] ?? {};
    final book = loan['book'] ?? {};
    final studentMessage = loan['student_message']?.toString() ?? '';
    final requestedDays = extractRequestedDays(studentMessage);
    final currentDueDate = getCurrentDueDate(loan);
    final extendedDueDate = getExtendedDueDate(loan, requestedDays);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalii cerere extindere'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student', style: Theme.of(context).textTheme.titleSmall),
                                Text(
                                  toTitleCase('${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(student['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.book_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Carte', style: Theme.of(context).textTheme.titleSmall),
                                Text(
                                  book['name'] ?? 'Carte necunoscută',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(book['author'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.timer_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Zile solicitate', style: Theme.of(context).textTheme.titleSmall),
                                Text(
                                  '${requestedDays ?? 'necunoscut'} zile',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (currentDueDate != null && extendedDueDate != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Data curentă de returnare',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentDueDate.toString().split(' ')[0],
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Data extinsă de returnare',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          extendedDueDate.toString().split(' ')[0],
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (studentMessage.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.message_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mesaj student', style: Theme.of(context).textTheme.titleSmall),
                                  Text(studentMessage, style: Theme.of(context).textTheme.bodyLarge),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ApiService.approveExtension(
                            borrowingId: loan['id'],
                            requestedDays: requestedDays ?? (loan['loan_duration_days'] ?? 14),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Extindere aprobată cu succes!'), backgroundColor: Colors.green),
                            );
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ExtensionRequestsScreen()),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Eroare la aprobare: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aprobă'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ApiService.declineExtension(borrowingId: loan['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Extindere respinsă cu succes!'), backgroundColor: Colors.orange),
                            );
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ExtensionRequestsScreen()),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Eroare la respingere: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Respinge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
} 