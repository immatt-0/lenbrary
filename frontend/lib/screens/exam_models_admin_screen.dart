import 'package:flutter/material.dart';
import './add_exam_model_screen.dart';
import '../services/api_service.dart';

class ExamModel {
  String name;
  String type; // 'EN' or 'BAC'
  String pdfFileName;
  ExamModel(
      {required this.name, required this.type, required this.pdfFileName});
}

class ExamModelsAdminScreen extends StatefulWidget {
  const ExamModelsAdminScreen({Key? key}) : super(key: key);

  @override
  State<ExamModelsAdminScreen> createState() => _ExamModelsAdminScreenState();
}

class _ExamModelsAdminScreenState extends State<ExamModelsAdminScreen> {
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

  List<dynamic> get _filteredModels {
    return _models.where((model) {
      final typeMatch = _selectedType == null || model['type'] == _selectedType;
      final categoryMatch = _selectedCategory == null || model['category'] == _selectedCategory;
      final nameMatch = model['name'] != null && model['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && categoryMatch && nameMatch;
    }).toList();
  }

  Future<void> _fetchExamModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await ApiService.fetchExamModels();
      print('Fetched models: ' + models.toString());
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching models: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcarea modelelor: $e')),
      );
    }
  }

  Future<void> _addExamModel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExamModelScreen(),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      await _fetchExamModels();
    }
  }

  Future<void> _deleteModel(int id) async {
    try {
      await ApiService.deleteExamModel(id);
      await _fetchExamModels();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la ștergere: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lenbrary',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/success');
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Modele de examene',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
            ElevatedButton(
              onPressed: _addExamModel,
              child: const Text('Adaugă model de examen'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aici poți adăuga modele de examene pentru studenți!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredModels.isEmpty
                      ? const Center(
                          child: Text(
                            'Nu există modele de examene adăugate.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredModels.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModels[index];
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteModel(model['id']),
                                ),
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
