class TrainingData {
  final List<double> features;
  final int label;
  final Map<String, dynamic> metadata;

  TrainingData(
    this.features,
    this.label, {
    this.metadata = const {},
  });
}

class TrainingBatch {
  final List<TrainingData> samples;
  final int batchSize;
  final double complexity;

  TrainingBatch(this.samples)
      : batchSize = samples.length,
        complexity = _calculateComplexity(samples);

  static double _calculateComplexity(List<TrainingData> samples) {
    // Placeholder for complexity calculation
    return 0.5;
  }
}

class TrainingResult {
  // For now, we'll keep this simple. It will be expanded later.
  final double finalAccuracy;
  final Duration totalTrainingTime;

  TrainingResult({
    required this.finalAccuracy,
    required this.totalTrainingTime,
  });
}
