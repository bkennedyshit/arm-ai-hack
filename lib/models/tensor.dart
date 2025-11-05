import 'dart:math';
import 'dart:typed_data';

class Tensor {
  final List<double> data;
  final List<int> shape;

  Tensor(this.data, this.shape);

  factory Tensor.random(List<int> shape, double min, double max) {
    final data = List<double>.filled(shape.reduce((a, b) => a * b), 0.0);
    final random = Random();
    for (int i = 0; i < data.length; i++) {
      data[i] = random.nextDouble() * (max - min) + min;
    }
    return Tensor(data, shape);
  }

  Tensor forward(Tensor input) {
    return input.dot(this);
  }

  Tensor backward(Tensor activations, Tensor grad) {
    final weightGrad = activations.transpose().dot(grad);
    final inputGrad = grad.dot(this.transpose());
    return inputGrad;
  }

  Tensor transpose() {
    if (shape.length != 2) {
      throw Exception('Transpose is only supported for 2D tensors');
    }
    final result = Tensor.random([shape[1], shape[0]], 0, 0);
    for (int i = 0; i < shape[0]; i++) {
      for (int j = 0; j < shape[1]; j++) {
        result.data[j * shape[0] + i] = data[i * shape[1] + j];
      }
    }
    return result;
  }

  Tensor dot(Tensor other) {
    if (shape.length != 2 || other.shape.length != 2 || shape[1] != other.shape[0]) {
      throw Exception('Invalid dimensions for matrix multiplication');
    }
    final result = Tensor.random([shape[0], other.shape[1]], 0, 0);
    for (int i = 0; i < shape[0]; i++) {
      for (int j = 0; j < other.shape[1]; j++) {
        double sum = 0;
        for (int k = 0; k < shape[1]; k++) {
          sum += data[i * shape[1] + k] * other.data[k * other.shape[1] + j];
        }
        result.data[i * other.shape[1] + j] = sum;
      }
    }
    return result;
  }
}

class Matrix extends Tensor {
  Matrix(List<double> data, int rows, int cols) : super(data, [rows, cols]);

  int get rows => shape[0];
  int get cols => shape[1];
}

class Vector extends Tensor {
  Vector(Float32List data) : super(data, [data.length]);

  int get length => shape[0];
}
