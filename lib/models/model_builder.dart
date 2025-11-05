import 'model_architecture.dart';
import 'layer.dart';

class ModelBuilder {
  final List<Layer> _layers = [];

  void add(Layer layer) {
    _layers.add(layer);
  }

  ModelArchitecture build() {
    return ModelArchitecture(layers: _layers.map((e) => e.parameterCount).toList());
  }
}
