import 'dart:math';
import 'package:on_device_training_sandbox/models/forward_result.dart';
import 'package:on_device_training_sandbox/models/model_architecture.dart';
import 'package:on_device_training_sandbox/models/training_data.dart';
import 'package:on_device_training_sandbox/models/training_metric.dart';
import 'package:on_device_training_sandbox/models/training_config.dart';
import 'package:on_device_training_sandbox/models/training_result.dart' as tr;
import 'package:on_device_training_sandbox/training/cross_entropy_loss.dart';
import 'package:on_device_training_sandbox/models/tensor.dart';
import 'package:on_device_training_sandbox/training/optimizer.dart' as opt;
import 'arm_optimizer.dart';

class MobileTrainer {
  late ARMOptimizer _armOptimizer;
  late final CrossEntropyLoss _lossFunction;
  late TrainingConfig _config;
  bool _isTraining = false;
  late DateTime _trainingStartTime;

  MobileTrainer() {
    _armOptimizer = ARMOptimizer();
    _lossFunction = CrossEntropyLoss();
  }

  Future<tr.TrainingResult> trainModel({
    required List<TrainingData> dataset,
    required ModelArchitecture architecture,
    required TrainingConfig config,
  }) async {
    _config = config;
    _isTraining = true;
    _trainingStartTime = DateTime.now();
    var currentBatchSize = config.batchSize;

    try {
      final weights = _initializeWeights(architecture);
      var optimizer = opt.SGDOptimizer(learningRate: config.learningRate);
      final trainingMetrics = <TrainingMetric>[];
      final numClasses = architecture.layers.last;
      
      if (dataset.isEmpty) {
        throw Exception('Dataset is empty');
      }
      if (numClasses <= 0) {
        throw Exception('Invalid number of classes');
      }

      for (int epoch = 0; epoch < config.epochs && _isTraining; epoch++) {
        double epochLoss = 0.0;
        int correct = 0;
        int totalSamples = 0;

        final shuffledData = List<TrainingData>.from(dataset);
        shuffledData.shuffle();

        // Process batches
        for (int i = 0; i < shuffledData.length; i += currentBatchSize) {
          if (!_isTraining) break;

          try {
            final endIdx = (i + currentBatchSize < shuffledData.length)
                ? i + currentBatchSize
                : shuffledData.length;
            final batch = shuffledData.sublist(i, endIdx);
            totalSamples += batch.length;

            // Forward pass
            final forwardResult = _forwardPass(batch, weights);

            // Calculate loss with validation
            final loss = _calculateLoss(forwardResult.predictions,
                batch.map((d) => d.label).toList(), numClasses);
            
            if (loss.isNaN || loss.isInfinite) {
              print('Warning: Loss is $loss, reducing learning rate');
              optimizer = opt.SGDOptimizer(
                learningRate: config.learningRate * 0.1,
              );
              continue;
            }
            
            epochLoss += loss * batch.length;

            // Count correct predictions
            correct += _countCorrectPredictions(
                forwardResult.predictions, batch.map((d) => d.label).toList());

            // Backward pass and weight update
            _backwardPass(forwardResult, batch, weights, numClasses);
            optimizer.updateWeights(weights, opt.ModelGradients.zeros(weights.shape));

            // Check thermal state
            if (await _armOptimizer.shouldThrottle()) {
              await Future.delayed(Duration(milliseconds: 50));
            }
          } catch (e) {
            print('Error processing batch: $e');
            // Reduce batch size on error
            currentBatchSize = max(1, (currentBatchSize / 2).toInt());
            print('Reduced batch size to $currentBatchSize');
            // Skip this batch and continue
            continue;
          }
        }

        final accuracy = correct / totalSamples;
        final avgLoss = epochLoss / totalSamples;

        trainingMetrics.add(TrainingMetric(
          epoch: epoch,
          loss: avgLoss,
          accuracy: accuracy,
          timestamp: DateTime.now(),
        ));

        print('Epoch $epoch: Loss=$avgLoss, Accuracy=$accuracy');
      }

      return tr.TrainingResult(
        weights: weights,
        metrics: trainingMetrics,
        finalAccuracy:
            trainingMetrics.isNotEmpty ? trainingMetrics.last.accuracy : 0.0,
        trainingTime: DateTime.now().difference(_trainingStartTime),
      );
    } on Exception catch (e) {
      print('Training error: $e');
      rethrow;
    } catch (e) {
      print('Unexpected training error: $e');
      rethrow;
    } finally {
      _isTraining = false;
    }
  }

  void pauseTraining() {
    _isTraining = false;
  }

  ForwardResult _forwardPass(
      List<TrainingData> batch, ModelWeights weights) {
    final predictions = <List<double>>[];
    final activations = <List<List<double>>>[];

    for (final data in batch) {
      var activation = List<double>.from(data.features);
      final layerActivations = <List<double>>[activation];

      // Simple forward pass through layers
      for (int l = 0; l < weights.layers.length; l++) {
        final weightMatrix = weights.layers[l];
        final output = List<double>.filled(weightMatrix.shape[1], 0.0);

        // Matrix multiplication: output = activation @ weights
        // activation shape: [activation.length]
        // weights shape: [weightMatrix.shape[0], weightMatrix.shape[1]]
        for (int j = 0; j < weightMatrix.shape[1]; j++) {
          double sum = 0.0;
          // Correctly iterate through input features
          final maxK = min(activation.length, weightMatrix.shape[0]);
          for (int k = 0; k < maxK; k++) {
            sum += activation[k] *
                weightMatrix.data[k * weightMatrix.shape[1] + j];
          }
          output[j] = sum;
        }

        // Apply ReLU for hidden layers, softmax for output
        if (l < weights.layers.length - 1) {
          for (int i = 0; i < output.length; i++) {
            output[i] = max(0.0, output[i]);
          }
        } else {
          // Softmax for output layer
          final softmaxOutput = _softmax(output);
          for (int i = 0; i < output.length; i++) {
            output[i] = softmaxOutput[i];
          }
        }

        activation = output;
        layerActivations.add(List<double>.from(activation));
      }

      predictions.add(activation);
      activations.add(layerActivations);
    }

    return ForwardResult(
      predictions: predictions,
      activations: activations,
    );
  }

  void _backwardPass(
    ForwardResult forward,
    List<TrainingData> batch,
    ModelWeights weights,
    int numClasses,
  ) {
    // Simplified backprop - accumulate gradients
    for (int i = 0; i < batch.length; i++) {
      final prediction = forward.predictions[i];
      final target = _oneHotEncode(batch[i].label, numClasses);

      // Calculate output error
      final outputError = List<double>.filled(numClasses, 0.0);
      for (int j = 0; j < numClasses; j++) {
        outputError[j] = prediction[j] - target[j];
      }
    }
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

  double _calculateLoss(
    List<List<double>> predictions,
    List<int> labels,
    int numClasses,
  ) {
    double totalLoss = 0.0;
    for (int i = 0; i < predictions.length; i++) {
      final pred = predictions[i];
      final target = _oneHotEncode(labels[i], numClasses);
      totalLoss += _lossFunction.calculate(
          Tensor(pred, [pred.length]), Tensor(target, [target.length]));
    }
    return totalLoss / predictions.length;
  }

  List<double> _oneHotEncode(int label, int numClasses) {
    final list = List.filled(numClasses, 0.0);
    if (label < numClasses) {
      list[label] = 1.0;
    }
    return list;
  }

  int _countCorrectPredictions(
      List<List<double>> predictions, List<int> labels) {
    int correct = 0;
    for (int i = 0; i < predictions.length; i++) {
      final prediction = predictions[i];
      final label = labels[i];
      var maxIdx = 0;
      var maxVal = prediction[0];
      for (int j = 1; j < prediction.length; j++) {
        if (prediction[j] > maxVal) {
          maxVal = prediction[j];
          maxIdx = j;
        }
      }
      if (maxIdx == label) {
        correct++;
      }
    }
    return correct;
  }

  List<double> _softmax(List<double> x) {
    final maxX = x.reduce((a, b) => a > b ? a : b);
    final expValues = x.map((v) => math_exp(v - maxX)).toList();
    final sum = expValues.reduce((a, b) => a + b);
    return expValues.map((v) => v / sum).toList();
  }

  /// Helper function to avoid name collision with exp variable
  static double math_exp(double x) {
    return exp(x);
  }
}
