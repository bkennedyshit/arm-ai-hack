import 'tensor.dart';
import '../training/optimizer.dart';

abstract class Layer {
  Tensor forward(Tensor input);
  Tensor backward(Tensor gradOutput);
  void updateWeights(Optimizer optimizer);
  int get parameterCount;
}
