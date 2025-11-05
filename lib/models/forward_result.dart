class ForwardResult {
  final List<List<double>> predictions;
  final List<dynamic> activations;

  ForwardResult({
    required this.predictions,
    required this.activations,
  });
}
