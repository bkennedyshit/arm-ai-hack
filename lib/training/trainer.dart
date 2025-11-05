import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:on_device_training_sandbox/models/forward_result.dart';
import 'package:on_device_training_sandbox/models/model_architecture.dart';
import 'package:on_device_training_sandbox/models/training_data.dart';
import 'package:on_device_training_sandbox/models/training_metric.dart';
import 'package:on_device_training_sandbox/models/training_config.dart';
import 'package:on_device_training_sandbox/models/training_result.dart';
import 'package:on_device_training_sandbox/training/cross_entropy_loss.dart';
import 'package:on_device_training_sandbox/models/tensor.dart';
import 'package:on_device_training_sandbox/training/optimizer.dart';
import 'arm_optimizer.dart';

class MobileTrainer {
  late ARMOptimizer _armOptimizer;
  late final CrossEntropyLoss _lossFunction;
  late TrainingConfig _config;
  
  // Native ARM NEON functions
  late final DynamicLibrary _nativeLib;
  late final void Function(Pointer<Float>, Pointer<Float>, int) _neonMatMul;
  MobileTrainer() {
    _armOptimizer = ARMOptimizer();
    _lossFunction = CrossEntropyLoss();
  }

  Future<TrainingResult> trainModel({
    required List<TrainingData> dataset,
    required ModelArchitecture architecture,
    required TrainingConfig config,
  }) async {
    _config = config;

    final weights = _initializeWeights(architecture);
    final optimizer = SGDOptimizer(learningRate: config.learningRate);

    final trainingMetrics = <TrainingMetric>[];

    for (int epoch = 0; epoch < config.epochs; epoch++) {
      double epochLoss = 0.0;
      int correct = 0;

      final shuffledData = List<TrainingData>.from(dataset)..shuffle();

      for (int i = 0; i < shuffledData.length; i += config.batchSize) {
        final batch = shuffledData.skip(i).take(config.batchSize).toList();

        final forwardResult = await _forwardPass(batch, weights);

        final loss = _calculateLoss(
            forwardResult.predictions, batch.map((d) => d.label).toList());
        epochLoss += loss;

        final gradients =
            await _backwardPass(forwardResult, batch, weights);

        optimizer.updateWeights(weights, gradients);

        correct += _countCorrectPredictions(
            forwardResult.predictions, batch.map((d) => d.label).toList());

        if (await _armOptimizer.shouldThrottle()) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      final accuracy = correct / dataset.length;
      final avgLoss = epochLoss / (dataset.length / config.batchSize);

      trainingMetrics.add(TrainingMetric(
        epoch: epoch,
        loss: avgLoss,
        accuracy: accuracy,
        timestamp: DateTime.now(),
      ));

      print('Epoch $epoch: Loss=$avgLoss, Accuracy=$accuracy');
    }

    return TrainingResult(
      weights: weights,
      metrics: trainingMetrics,
      finalAccuracy: trainingMetrics.last.accuracy,
      trainingTime: DateTime.now().difference(trainingMetrics.first.timestamp),
    );
  }

  Future<ForwardResult> _forwardPass(
      List<TrainingData> batch, ModelWeights weights) async {
    final predictions = <List<double>>[];
    final activations = <List<dynamic>>[];

    for (final data in batch) {
      Tensor input = Tensor(data.features, [data.features.length]);
      final layerActivations = [];

      for (final layer in weights.layers) {
        input = (layer as dynamic).forward(input);
        layerActivations.add(input);
      }
      predictions.add(input.data);
      activations.add(layerActivations);
    }

    return ForwardResult(
      predictions: predictions,
      activations: activations,
    );
  }

  Future<ModelGradients> _backwardPass(
      ForwardResult forward, List<TrainingData> batch, ModelWeights weights) async {
    final gradients = ModelGradients.zeros(weights.shape);

    for (int i = 0; i < batch.length; i++) {
      final prediction = forward.predictions[i];
      final target = _oneHotEncode(batch[i].label, prediction.length);

      Tensor grad = _lossFunction.derivative(
          Tensor(prediction, [prediction.length]), Tensor(target, [target.length]));

      for (int j = weights.layers.length - 1; j >= 0; j--) {
        grad = (weights.layers[j] as dynamic)
            .backward(forward.activations[i][j], grad);
      }
    }
    return gradients;
  }

  ModelWeights _initializeWeights(ModelArchitecture arch) {
    final layers = <Tensor>[];
    for (int i = 0; i < arch.layers.length - 1; i++) {
      final fanIn = arch.layers[i];
      final fanOut = arch.layers[i + 1];
      final limit = sqrt(6.0 / (fanIn + fanOut));
      layers.add(Tensor.random([fanIn, fanOut], -limit, limit));
    }
    return ModelWeights(layers, arch.layers);
  }

  double _calculateLoss(List<List<double>> predictions, List<int> labels) {
    double totalLoss = 0.0;
    for (int i = 0; i < predictions.length; i++) {
      final pred = predictions[i];
      final target = _oneHotEncode(labels[i], pred.length);
      totalLoss += _lossFunction.calculate(
          Tensor(pred, [pred.length]), Tensor(target, [target.length]));
    }
    return totalLoss / predictions.length;
  }

  List<double> _oneHotEncode(int label, int numClasses) {
    final list = List.filled(numClasses, 0.0);
    list[label] = 1.0;
    return list;
  }

  int _countCorrectPredictions(
      List<List<double>> predictions, List<int> labels) {
    int correct = 0;
    for (int i = 0; i < predictions.length; i++) {
      final prediction = predictions[i];
      final label = labels[i];
      final predictedLabel =
          prediction.indexOf(prediction.reduce((max, e) => e > max ? e : max));
      if (predictedLabel == label) {
        correct++;
      }
    }
    return correct;
  }
}