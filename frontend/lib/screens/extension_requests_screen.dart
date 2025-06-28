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
      // Filter for loans with a pending extension request
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cereri de extindere')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _requests.isEmpty
                  ? const Center(child: Text('Nu există cereri de extindere.'))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final loan = _requests[index];
                        final student = loan['student']?['user'] ?? {};
                        final book = loan['book'] ?? {};
                        final studentMessage = loan['student_message']?.toString() ?? '';
                        final requestedDays = extractRequestedDays(studentMessage);
                        return ListTile(
                          title: Text('${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Carte: ${book['name'] ?? 'necunoscută'}'),
                              Text('Zile solicitate: ${requestedDays ?? 'necunoscut'}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExtensionRequestDetailScreen(loan: loan),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
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

  @override
  Widget build(BuildContext context) {
    final student = loan['student']?['user'] ?? {};
    final book = loan['book'] ?? {};
    final studentMessage = loan['student_message']?.toString() ?? '';
    final requestedDays = extractRequestedDays(studentMessage);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalii cerere extindere')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student['first_name'] ?? ''} ${student['last_name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Carte: ${book['name'] ?? 'necunoscută'}'),
            Text('Autor: ${book['author'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Zile solicitate: ${requestedDays ?? 'necunoscut'}'),
            const SizedBox(height: 8),
            Text('Mesaj student: $studentMessage'),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ApiService.approveExtension(
                        borrowingId: loan['id'],
                        requestedDays: requestedDays ?? (loan['loan_duration_days'] ?? 14),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extindere aprobată!'), backgroundColor: Colors.green));
                      // Navigate back and refresh the extension requests list
                      Navigator.pop(context);
                      // Trigger a refresh of the parent screen
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExtensionRequestsScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare la aprobare: ${e.toString()}'), backgroundColor: Colors.red));
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aprobă'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ApiService.declineExtension(borrowingId: loan['id']);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extindere respinsă!'), backgroundColor: Colors.orange));
                      // Navigate back and refresh the extension requests list
                      Navigator.pop(context);
                      // Trigger a refresh of the parent screen
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExtensionRequestsScreen(),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare la respingere: ${e.toString()}'), backgroundColor: Colors.red));
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Respinge'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 