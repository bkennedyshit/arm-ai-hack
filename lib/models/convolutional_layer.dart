import '../models/layer.dart';
import '../models/tensor.dart';
import '../training/optimizer.dart';

class ConvolutionalLayer extends Layer {
  @override
  Tensor backward(Tensor gradOutput) {
    // TODO: implement backward
    throw UnimplementedError();
  }

  @override
  Tensor forward(Tensor input) {
    // TODO: implement forward
    throw UnimplementedError();
  }

  @override
  // TODO: implement parameterCount
  int get parameterCount => throw UnimplementedError();

  @override
  void updateWeights(Optimizer optimizer) {
    // TODO: implement updateWeights
  }
}
