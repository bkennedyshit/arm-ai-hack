import 'dart:math';

import 'package:on_device_training_sandbox/models/tensor.dart';
import 'package:on_device_training_sandbox/training/loss_function.dart';

class CrossEntropyLoss implements LossFunction {
  @override
  double calculate(Tensor predictions, Tensor targets) {
    double loss = 0.0;
    for (int i = 0; i < predictions.data.length; i++) {
      loss -= targets.data[i] * log(predictions.data[i] + 1e-15);
    }
    return loss;
  }

  @override
  Tensor derivative(Tensor predictions, Tensor targets) {
    final gradientData = List<double>.filled(predictions.data.length, 0.0);
    for (int i = 0; i < predictions.data.length; i++) {
      gradientData[i] =
          -(targets.data[i] / (predictions.data[i] + 1e-15));
    }
    return Tensor(gradientData, predictions.shape);
  }
}
