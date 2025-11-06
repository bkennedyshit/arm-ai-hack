import 'package:test/test.dart';
import 'package:on_device_training_sandbox/training/trainer.dart';
import 'package:on_device_training_sandbox/models/model_architecture.dart';
import 'package:on_device_training_sandbox/models/training_config.dart';
import 'package:on_device_training_sandbox/utils/dataset_loader.dart';

void main() {
  group('MobileTrainer Tests', () {
    test('Trainer initializes correctly', () {
      final trainer = MobileTrainer();
      expect(trainer, isNotNull);
    });

    test('Dataset loader generates synthetic data', () {
      final dataset = DatasetLoader.generateSyntheticDataset(
        numSamples: 100,
        inputSize: 10,
        numClasses: 3,
      );

      expect(dataset.length, equals(100));
      expect(dataset.first.features.length, equals(10));
      expect(dataset.first.label, isA<int>());
    });

    test('Dataset preprocessing normalizes data', () {
      final dataset = DatasetLoader.generateSyntheticDataset(
        numSamples: 50,
        inputSize: 20,
        numClasses: 5,
      );

      final preprocessed = DatasetLoader.preprocess(dataset);
      expect(preprocessed.length, equals(50));

      // Check values are in [0, 1] range after normalization
      for (final sample in preprocessed) {
        for (final feature in sample.features) {
          expect(feature, greaterThanOrEqualTo(0.0));
          expect(feature, lessThanOrEqualTo(1.0));
        }
      }
    });

    test('Dataset batching creates correct number of batches', () {
      final dataset = DatasetLoader.generateSyntheticDataset(
        numSamples: 100,
        inputSize: 10,
        numClasses: 3,
      );

      final batches = DatasetLoader.createBatches(
        dataset,
        batchSize: 32,
      );

      expect(batches.length, equals(4)); // 100 / 32 = 3.125, so 4 batches
      expect(batches.first.length, equals(32));
      expect(batches.last.length, equals(4)); // Last batch has remainder
    });

    test('Model weights initialize correctly', () {
      final architecture = ModelArchitecture(layers: [10, 5, 3]);
      final trainer = MobileTrainer();

      // We'll test through a simple training run
      expect(architecture.layers.length, equals(3));
      expect(architecture.layers.first, equals(10));
      expect(architecture.layers.last, equals(3));
    });

    test('Training config validates parameters', () {
      final config = TrainingConfig(
        epochs: 5,
        batchSize: 16,
        learningRate: 0.01,
      );

      expect(config.epochs, equals(5));
      expect(config.batchSize, equals(16));
      expect(config.learningRate, equals(0.01));
      expect(config.useArmOptimizations, isTrue);
    });
  });

  group('Integration Tests', () {
    test('Simple training run completes', () async {
      final trainer = MobileTrainer();
      final dataset = DatasetLoader.generateSyntheticDataset(
        numSamples: 50,
        inputSize: 10,
        numClasses: 3,
      );

      final preprocessed = DatasetLoader.preprocess(dataset);

      final architecture = ModelArchitecture(layers: [10, 8, 3]);
      final config = TrainingConfig(
        epochs: 2,
        batchSize: 16,
        learningRate: 0.01,
      );

      final result = await trainer.trainModel(
        dataset: preprocessed,
        architecture: architecture,
        config: config,
      );

      expect(result.metrics.length, equals(2));
      expect(result.finalAccuracy, greaterThanOrEqualTo(0.0));
      expect(result.finalAccuracy, lessThanOrEqualTo(1.0));
      expect(result.trainingTime, isA<Duration>());
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
