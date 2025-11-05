enum LayerType {
  dense,
  convolutional2d,
  maxPooling2d,
  dropout,
  batchNormalization,
  flatten
}

class ModelArchitecture {
  final List<LayerConfig> layers;

  ModelArchitecture(this.layers);
}

class LayerConfig {
  final LayerType type;
  final Map<String, dynamic> params;

  LayerConfig(this.type, this.params);
}

class TrainingConfig {
  final int epochs;
  final int batchSize;
  final double learningRate;
  final double validationSplit;
  final bool shuffle;
  final bool useArmOptimizations;

  TrainingConfig({
    required this.epochs,
    required this.batchSize,
    required this.learningRate,
    this.validationSplit = 0.2,
    this.shuffle = true,
    this.useArmOptimizations = true,
  });
}
