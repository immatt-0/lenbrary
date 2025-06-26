import 'package:flutter/material.dart';
import 'exam_models_admin_screen.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddExamModelScreen extends StatefulWidget {
  const AddExamModelScreen({Key? key}) : super(key: key);

  @override
  State<AddExamModelScreen> createState() => _AddExamModelScreenState();
}

class _AddExamModelScreenState extends State<AddExamModelScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _examName;
  String? _examType; // 'EN' or 'BAC'
  String? _category; // 'Matematica' or 'Romana'
  String? _pdfFileName;
  String? _pdfFilePath;
  Uint8List? _pdfFileBytes;
  bool _isLoading = false;

  void _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // get bytes for web
    );
    if (result != null) {
      setState(() {
        _pdfFileName = result.files.single.name;
        if (kIsWeb) {
          _pdfFileBytes = result.files.single.bytes;
          _pdfFilePath = null;
        } else {
          _pdfFilePath = result.files.single.path;
          _pdfFileBytes = null;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        (_pdfFilePath != null || _pdfFileBytes != null) &&
        _examType != null &&
        _category != null) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.addExamModel(
          name: _examName!,
          type: _examType!,
          category: _category!,
          pdfFilePath: _pdfFilePath,
          pdfFileBytes: _pdfFileBytes,
          pdfFileName: _pdfFileName,
        );
        print('Add exam model result: ' + result.toString());
        setState(() => _isLoading = false);
        Navigator.pop(context, result);
      } catch (e) {
        setState(() => _isLoading = false);
        print('Error adding exam model: ' + e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la adăugare: $e')),
        );
      }
    } else if (_pdfFilePath == null && _pdfFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să selectați un fișier PDF.')),
      );
    } else if (_examType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vă rugăm să selectați tipul examenului.')),
      );
    } else if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vă rugăm să selectați materia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaugă Model de Examen')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Matematica', child: Text('Matematică')),
                      DropdownMenuItem(
                          value: 'Romana', child: Text('Română')),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                    validator: (value) =>
                        value == null ? 'Selectați materia' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_pdfFileName == null ? 'Alege PDF' : _pdfFileName!),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Adaugă modelul'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
