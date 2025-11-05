class TrainingMetric {
  final int epoch;
  final double loss;
  final double accuracy;
  final DateTime timestamp;

  TrainingMetric({
    required this.epoch,
    required this.loss,
    required this.accuracy,
    required this.timestamp,
  });
}
