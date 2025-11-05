import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Tutorial'),
      ),
      body: const Center(
        child: Text('Welcome to the interactive tutorial!'),
      ),
    );
  }
}
