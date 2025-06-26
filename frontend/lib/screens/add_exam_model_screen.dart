import 'package:flutter/material.dart';
import 'exam_models_admin_screen.dart';

class AddExamModelScreen extends StatefulWidget {
  const AddExamModelScreen({Key? key}) : super(key: key);

  @override
  State<AddExamModelScreen> createState() => _AddExamModelScreenState();
}

class _AddExamModelScreenState extends State<AddExamModelScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _examName;
  String? _examType; // 'EN' or 'BAC'
  String? _pdfFileName;

  void _pickPdf() async {
    // Placeholder for PDF picker
    setState(() {
      _pdfFileName = 'exemplu_model.pdf';
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate() &&
        _pdfFileName != null &&
        _examType != null) {
      _formKey.currentState!.save();
      // Return the new ExamModel to the previous screen
      Navigator.pop(
          context,
          ExamModel(
            name: _examName!,
            type: _examType!,
            pdfFileName: _pdfFileName!,
          ));
    } else if (_pdfFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să selectați un fișier PDF.')),
      );
    } else if (_examType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vă rugăm să selectați tipul examenului.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaugă Model de Examen')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nume model examen',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduceți un nume'
                    : null,
                onSaved: (value) => _examName = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tip examen',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'EN', child: Text('Evaluare Națională (EN)')),
                  DropdownMenuItem(
                      value: 'BAC', child: Text('Bacalaureat (BAC)')),
                ],
                onChanged: (value) => setState(() => _examType = value),
                validator: (value) =>
                    value == null ? 'Selectați tipul examenului' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.attach_file),
                label: Text(_pdfFileName == null ? 'Alege PDF' : _pdfFileName!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Adaugă modelul'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
