import 'package:on_device_training_sandbox/models/tensor.dart';

class ModelArchitecture {
  final List<int> layers;

  ModelArchitecture({required this.layers});
}

class ModelWeights {
  final List<Tensor> layers;
  final List<int> shape;

  ModelWeights(this.layers, this.shape);

  void setLayer(int i, List<List<double>> randomMatrix) {
    // Placeholder
  }
}

class ModelGradients {
  final List<Tensor> layers;

  ModelGradients(this.layers);

  factory ModelGradients.zeros(List<int> shape) {
    final layers = <Tensor>[];
    for (int i = 0; i < shape.length - 1; i++) {
      layers.add(Tensor.random([shape[i], shape[i + 1]], 0, 0));
    }
    return ModelGradients(layers);
  }

  void scale(double d) {
    // Placeholder
  }
}
