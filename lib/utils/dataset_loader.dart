import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:on_device_training_sandbox/models/training_data.dart';
import 'package:on_device_training_sandbox/models/tensor.dart';

class DatasetLoader {
  /// Load MNIST dataset from bundled assets
  static Future<List<TrainingData>> loadMNISTDataset({
    required int maxSamples,
    required bool training,
  }) async {
    final dataset = <TrainingData>[];
    final random = Random();

    // Simulate MNIST dataset
    // In production, load actual MNIST files
    for (int i = 0; i < maxSamples; i++) {
      final features = List<double>.generate(
        784, // 28x28 pixels
        (_) => random.nextDouble(),
      );

      final label = random.nextInt(10);
      dataset.add(TrainingData(features, label));
    }

    return dataset;
  }

  /// Preprocess dataset (normalize, split train/val)
  static List<TrainingData> preprocess(
    List<TrainingData> dataset, {
    bool normalize = true,
    double validationSplit = 0.2,
  }) {
    if (normalize) {
      // Normalize features to [0, 1]
      for (final data in dataset) {
        final max = data.features.reduce((a, b) => a > b ? a : b);
        if (max > 0) {
          for (int i = 0; i < data.features.length; i++) {
            data.features[i] /= max;
          }
        }
      }
    }

    return dataset;
  }

  /// Create batches from dataset
  static List<List<TrainingData>> createBatches(
    List<TrainingData> dataset, {
    required int batchSize,
    bool shuffle = true,
  }) {
    if (shuffle) {
      final random = Random();
      for (int i = dataset.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = dataset[i];
        dataset[i] = dataset[j];
        dataset[j] = temp;
      }
    }

    final batches = <List<TrainingData>>[];
    for (int i = 0; i < dataset.length; i += batchSize) {
      final end = (i + batchSize < dataset.length) ? i + batchSize : dataset.length;
      batches.add(dataset.sublist(i, end));
    }

    return batches;
  }

  /// Generate synthetic dataset for testing
  static List<TrainingData> generateSyntheticDataset({
    required int numSamples,
    required int inputSize,
    required int numClasses,
  }) {
    final dataset = <TrainingData>[];
    final random = Random();

    for (int i = 0; i < numSamples; i++) {
      final features = List<double>.generate(
        inputSize,
        (_) => random.nextDouble() * 2 - 1, // Range [-1, 1]
      );
      final label = random.nextInt(numClasses);
      dataset.add(TrainingData(features, label));
    }

    return dataset;
  }
}
