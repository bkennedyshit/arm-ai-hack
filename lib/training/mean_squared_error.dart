import '../models/tensor.dart';
import 'loss_function.dart';

class MeanSquaredError extends LossFunction {
  @override
  double calculate(Tensor predictions, Tensor targets) {
    double sum = 0;
    for (int i = 0; i < predictions.data.length; i++) {
      final diff = predictions.data[i] - targets.data[i];
      sum += diff * diff;
    }
    return sum / predictions.data.length;
  }

  @override
  Tensor derivative(Tensor predictions, Tensor targets) {
    final derivativeData = predictions.data.buffer.asFloat32List();
    for (int i = 0; i < predictions.data.length; i++) {
      derivativeData[i] = 2 * (predictions.data[i] - targets.data[i]);
    }
    return Tensor(derivativeData, predictions.shape);
  }
}
