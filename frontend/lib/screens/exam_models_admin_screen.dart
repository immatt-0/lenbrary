import 'package:flutter/material.dart';
import './add_exam_model_screen.dart';

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
  final List<ExamModel> _models = [];
  int? _editingIndex;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _addExamModel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExamModelScreen(),
      ),
    );
    if (result != null && result is ExamModel) {
      setState(() {
        _models.add(result);
      });
    }
  }

  void _deleteModel(int index) {
    setState(() {
      _models.removeAt(index);
    });
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text = _models[index].name;
    });
  }

  void _saveEdit(int index) {
    setState(() {
      _models[index].name = _editController.text;
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrează Modele de Examene')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addExamModel,
              child: const Text('Adaugă model de examen'),
            ),
            const SizedBox(height: 24),
            const Text('Aici poți adăuga modele de examene pentru studenți!'),
            const SizedBox(height: 32),
            Expanded(
              child: _models.isEmpty
                  ? const Text('Nu există modele de examene adăugate.')
                  : ListView.builder(
                      itemCount: _models.length,
                      itemBuilder: (context, index) {
                        final model = _models[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(model.type == 'EN'
                                ? Icons.school
                                : Icons.workspace_premium),
                            title: _editingIndex == index
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _editController,
                                          autofocus: true,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () => _saveEdit(index),
                                      ),
                                    ],
                                  )
                                : Text(model.name),
                            subtitle: Text(
                                '${model.type == 'EN' ? 'Evaluare Națională' : 'Bacalaureat'}\n${model.pdfFileName}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _startEdit(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteModel(index),
                                ),
                              ],
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
