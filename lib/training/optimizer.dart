import 'package:on_device_training_sandbox/models/model_architecture.dart';

abstract class Optimizer {
  void updateWeights(ModelWeights weights, ModelGradients gradients);
}

class SGDOptimizer extends Optimizer {
  final double learningRate;

  SGDOptimizer({required this.learningRate});

  @override
  void updateWeights(ModelWeights weights, ModelGradients gradients) {
    for (int i = 0; i < weights.layers.length; i++) {
      weights.layers[i].data
          .asMap()
          .forEach((j, value) => value -= learningRate * gradients.layers[i].data[j]);
    }
  }
}

class ModelGradients {
  ModelGradients.zeros(List<int> shape);

  void scale(double d) {
    // Placeholder
  }
}
