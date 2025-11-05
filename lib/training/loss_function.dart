import '../models/tensor.dart';

abstract class LossFunction {
  double calculate(Tensor predictions, Tensor targets);
  Tensor derivative(Tensor predictions, Tensor targets);
}
