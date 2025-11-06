import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStep = 0;

  final List<Tutorial> _tutorials = [
    Tutorial(
      title: 'Neural Networks Basics',
      description: 'Learn how artificial neural networks work.',
      content:
          'A neural network is a set of algorithms that process data by layers. '
          'Input layer receives data, hidden layers process it, and the output layer produces results.',
      icon: Icons.psychology,
    ),
    Tutorial(
      title: 'Forward Pass',
      description: 'Understanding forward propagation.',
      content:
          'The forward pass is where data flows through the network from input to output. '
          'Each neuron performs: output = activation(weights · input + bias)',
      icon: Icons.arrow_forward,
    ),
    Tutorial(
      title: 'Backward Pass',
      description: 'Understanding backpropagation.',
      content:
          'Backpropagation calculates gradients by working backwards from the output. '
          'These gradients tell us how to adjust weights to reduce loss.',
      icon: Icons.arrow_back,
    ),
    Tutorial(
      title: 'Optimization',
      description: 'How SGD updates weights.',
      content:
          'Stochastic Gradient Descent (SGD) updates weights by moving them in the direction '
          'opposite to the gradient: weight = weight - learning_rate · gradient',
      icon: Icons.trending_down,
    ),
    Tutorial(
      title: 'ARM NEON SIMD',
      description: 'ARM optimization for faster computation.',
      content:
          'ARM NEON processes 4 float32 values in parallel using SIMD instructions, '
          'achieving 2.5x speedup on matrix operations.',
      icon: Icons.speed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tutorial = _tutorials[_currentStep];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Tutorial'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _tutorials.length,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step ${_currentStep + 1} of ${_tutorials.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // Icon and title
                  Icon(
                    tutorial.icon,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tutorial.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tutorial.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Content card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        tutorial.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentStep > 0
                      ? () {
                          setState(() => _currentStep--);
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentStep < _tutorials.length - 1
                      ? () {
                          setState(() => _currentStep++);
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Tutorial {
  final String title;
  final String description;
  final String content;
  final IconData icon;

  Tutorial({
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
  });
}
