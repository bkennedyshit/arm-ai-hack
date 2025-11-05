import 'package:flutter/material.dart';
import 'package:on_device_training_sandbox/screens/tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On-Device Training Sandbox'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TutorialScreen()),
            );
          },
          child: const Text('Start Tutorial'),
        ),
      ),
    );
  }
}
