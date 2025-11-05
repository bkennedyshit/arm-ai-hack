import 'dart:typed_data';
import '../models/layer.dart';
import '../models/tensor.dart';
import '../training/optimizer.dart';
import 'dart:math';

class DenseLayer extends Layer {
  late Matrix weights;
  late Vector biases;
  late Tensor _lastInput;

  DenseLayer(int inputSize, int outputSize) {
    final rand = Random();
    final weightsData = Float32List(inputSize * outputSize);
    for (int i = 0; i < weightsData.length; i++) {
      weightsData[i] = (rand.nextDouble() - 0.5) * 2;
    }
    weights = Matrix(weightsData, inputSize, outputSize);

    final biasesData = Float32List(outputSize);
    for (int i = 0; i < biasesData.length; i++) {
      biasesData[i] = (rand.nextDouble() - 0.5) * 2;
    }
    biases = Vector(biasesData);
  }

  @override
  Tensor backward(Tensor gradOutput) {
    final gradOutputMatrix = gradOutput as Matrix;
    final lastInputMatrix = _lastInput as Matrix;

    final weightGradsData = Float32List(weights.data.length);
    for (int i = 0; i < lastInputMatrix.cols; i++) {
      for (int j = 0; j < gradOutputMatrix.cols; j++) {
        double sum = 0;
        for (int k = 0; k < lastInputMatrix.rows; k++) {
          sum += lastInputMatrix.data[k * lastInputMatrix.cols + i] *
              gradOutputMatrix.data[k * gradOutputMatrix.cols + j];
        }
        weightGradsData[i * weights.cols + j] = sum;
      }
    }

    final biasGradsData = Float32List(biases.data.length);
    for (int i = 0; i < gradOutputMatrix.rows; i++) {
      for (int j = 0; j < gradOutputMatrix.cols; j++) {
        biasGradsData[j] += gradOutputMatrix.data[i * gradOutputMatrix.cols + j];
      }
    }

    final inputGradsData = Float32List(lastInputMatrix.data.length);
    for (int i = 0; i < lastInputMatrix.rows; i++) {
      for (int j = 0; j < lastInputMatrix.cols; j++) {
        double sum = 0;
        for (int k = 0; k < gradOutputMatrix.cols; k++) {
          sum += gradOutputMatrix.data[i * gradOutputMatrix.cols + k] *
              weights.data[j * weights.cols + k];
        }
        inputGradsData[i * lastInputMatrix.cols + j] = sum;
      }
    }

    return Matrix(
        inputGradsData, lastInputMatrix.rows, lastInputMatrix.cols);
  }

  @override
  Tensor forward(Tensor input) {
    _lastInput = input;
    final outputData = Float32List(biases.length);
    final inputMatrix = input as Matrix;

    for (int i = 0; i < inputMatrix.rows; i++) {
      for (int j = 0; j < weights.cols; j++) {
        double sum = 0;
        for (int k = 0; k < inputMatrix.cols; k++) {
          sum += inputMatrix.data[i * inputMatrix.cols + k] *
              weights.data[k * weights.cols + j];
        }
        outputData[i * weights.cols + j] = sum + biases.data[j];
      }
    }

    return Matrix(outputData, inputMatrix.rows, weights.cols);
  }

  @override
  int get parameterCount => weights.data.length + biases.data.length;

  @override
  void updateWeights(Optimizer optimizer) {
    // This is a placeholder for a more sophisticated gradient update
    // final weightGradients = getWeightGradients();
    // final biasGradients = getBiasGradients();

    // for (int i = 0; i < weights.data.length; i++) {
    //   weights.data[i] -= optimizer.learningRate * weightGradients.data[i];
    // }
    // for (int i = 0; i < biases.data.length; i++) {
    //   biases.data[i] -= optimizer.learningRate * biasGradients.data[i];
    // }
  }
}
