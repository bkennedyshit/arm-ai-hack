class TrainingConfig {
  final int epochs;
  final int batchSize;
  final double learningRate;
  final bool useArmOptimizations;

  TrainingConfig({
    required this.epochs,
    required this.batchSize,
    required this.learningRate,
    this.useArmOptimizations = true,
  });
}
