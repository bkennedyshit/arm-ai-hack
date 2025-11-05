import '../models/model_architecture.dart';
import '../models/dense_layer.dart';
import '../models/layer.dart';

abstract class Optimizer {
  void updateWeights(List<Layer> layers);
}

class SGDOptimizer extends Optimizer {
  final double learningRate;

  SGDOptimizer({required this.learningRate});

  @override
  void updateWeights(List<Layer> layers) {
    for (final layer in layers) {
      if (layer is DenseLayer) {
        final denseLayer = layer;
        // This is a placeholder for a more sophisticated gradient update
        // final weightGradients = denseLayer.getWeightGradients();
        // final biasGradients = denseLayer.getBiasGradients();

        // for (int i = 0; i < denseLayer.weights.data.length; i++) {
        //   denseLayer.weights.data[i] -= learningRate * weightGradients.data[i];
        // }
        // for (int i = 0; i < denseLayer.biases.data.length; i++) {
        //   denseLayer.biases.data[i] -= learningRate * biasGradients.data[i];
        // }
      }
    }
  }
}

class ModelGradients {
  ModelGradients.zeros(List<int> shape);

  void scale(double d) {
    // Placeholder
  }
}
