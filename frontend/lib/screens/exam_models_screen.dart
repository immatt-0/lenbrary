import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ExamModelsScreen extends StatefulWidget {
  const ExamModelsScreen({Key? key}) : super(key: key);

  @override
  State<ExamModelsScreen> createState() => _ExamModelsScreenState();
}

class _ExamModelsScreenState extends State<ExamModelsScreen> {
  List<dynamic> _models = [];
  bool _isLoading = true;
  String? _selectedType; // 'EN' or 'BAC'
  String? _selectedCategory; // 'Matematica' or 'Romana'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExamModels();
  }

  Future<void> _fetchExamModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await ApiService.fetchExamModels();
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea modelelor: $e')),
      );
    }
  }

  List<dynamic> get _filteredModels {
    return _models.where((model) {
      final typeMatch = _selectedType == null || model['type'] == _selectedType;
      final categoryMatch = _selectedCategory == null || model['category'] == _selectedCategory;
      final nameMatch = model['name'] != null && model['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && categoryMatch && nameMatch;
    }).toList();
  }

  void _openPdf(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu s-a putut deschide PDF-ul.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modele de examene'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Caută după nume',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tip examen',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Toate tipurile')),
                      DropdownMenuItem(value: 'EN', child: Text('Evaluare Națională')),
                      DropdownMenuItem(value: 'BAC', child: Text('Bacalaureat')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Toate materiile')),
                      DropdownMenuItem(value: 'Matematica', child: Text('Matematică')),
                      DropdownMenuItem(value: 'Romana', child: Text('Română')),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredModels.isEmpty
                      ? const Center(child: Text('Nu există modele de examene disponibile.'))
                      : ListView.builder(
                          itemCount: _filteredModels.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModels[index];
                            final pdfUrl = model['pdf_file'] != null
                                ? (model['pdf_file'].toString().startsWith('http')
                                    ? model['pdf_file']
                                    : ApiService.baseUrl + model['pdf_file'])
                                : null;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Icon(model['type'] == 'EN'
                                    ? Icons.school
                                    : Icons.workspace_premium),
                                title: Text(model['name'] ?? ''),
                                subtitle: Text(
                                  '${model['type'] == 'EN' ? 'Evaluare Națională' : 'Bacalaureat'} • '
                                  '${model['category'] == 'Matematica' ? 'Matematică' : 'Română'}',
                                ),
                                trailing: pdfUrl != null
                                    ? IconButton(
                                        icon: const Icon(Icons.picture_as_pdf),
                                        onPressed: () => _openPdf(pdfUrl),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
