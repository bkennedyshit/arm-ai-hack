class ModelArchitecture {
  final List<int> layers;

  ModelArchitecture({required this.layers});
}

class ModelWeights {
  final List<int> shape;

  ModelWeights(this.shape);

  void setLayer(int i, List<List<double>> randomMatrix) {
    // Placeholder
  }
}
