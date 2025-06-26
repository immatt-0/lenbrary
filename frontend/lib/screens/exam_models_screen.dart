import 'package:flutter/material.dart';

class ExamModelsScreen extends StatelessWidget {
  const ExamModelsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Models')),
      body: const Center(
        child: Text(
          'Here you will find exam models!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
