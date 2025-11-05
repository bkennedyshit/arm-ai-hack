import 'dart:typed_data';

class Tensor {
  final Float32List data;
  final List<int> shape;

  Tensor(this.data, this.shape);
}

class Matrix extends Tensor {
  Matrix(Float32List data, int rows, int cols) : super(data, [rows, cols]);

  int get rows => shape[0];
  int get cols => shape[1];
}

class Vector extends Tensor {
  Vector(Float32List data) : super(data, [data.length]);

  int get length => shape[0];
}
