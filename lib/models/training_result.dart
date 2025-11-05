import 'package:on_device_training_sandbox/models/training_metric.dart';
import 'package:on_device_training_sandbox/models/model_architecture.dart';

class TrainingResult {
  final ModelWeights weights;
  final List<TrainingMetric> metrics;
  final double finalAccuracy;
  final Duration trainingTime;

  TrainingResult({
    required this.weights,
    required this.metrics,
    required this.finalAccuracy,
    required this.trainingTime,
  });
}
