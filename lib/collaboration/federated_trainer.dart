import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Federated learning inspired by iPhone 16 Pro mesh networking
class FederatedTrainer {
  static const String defaultServer = 'ws://localhost:8080/federated';
  
  WebSocketChannel? _channel;
  final StreamController<FederatedUpdate> _updateController = StreamController.broadcast();
  
  Stream<FederatedUpdate> get updates => _updateController.stream;
  
  Future<void> joinFederatedSession(String sessionId) async {
    _channel = WebSocketChannel.connect(Uri.parse('$defaultServer/$sessionId'));
    
    _channel!.stream.listen((data) {
      final update = FederatedUpdate.fromJson(jsonDecode(data));
      _updateController.add(update);
    });
  }
  
  Future<void> shareGradients(List<double> gradients, double accuracy) async {
    if (_channel == null) return;
    
    final update = FederatedUpdate(
      deviceId: _getDeviceId(),
      gradients: gradients,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );
    
    _channel!.sink.add(jsonEncode(update.toJson()));
  }
  
  Future<void> receiveAggregatedModel(Function(List<double>) onModelUpdate) async {
    updates.where((update) => update.type == UpdateType.aggregated).listen((update) {
      onModelUpdate(update.gradients);
    });
  }
  
  // Real-time training metrics sharing
  Future<void> shareTrainingMetrics({
    required int epoch,
    required double loss,
    required double accuracy,
  }) async {
    if (_channel == null) return;
    
    final metrics = TrainingMetrics(
      deviceId: _getDeviceId(),
      epoch: epoch,
      loss: loss,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );
    
    _channel!.sink.add(jsonEncode({
      'type': 'metrics',
      'data': metrics.toJson(),
    }));
  }
  
  String _getDeviceId() {
    // Generate unique device identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  void dispose() {
    _channel?.sink.close();
    _updateController.close();
  }
}

class FederatedUpdate {
  final String deviceId;
  final List<double> gradients;
  final double accuracy;
  final DateTime timestamp;
  final UpdateType type;
  
  FederatedUpdate({
    required this.deviceId,
    required this.gradients,
    required this.accuracy,
    required this.timestamp,
    this.type = UpdateType.gradient,
  });
  
  factory FederatedUpdate.fromJson(Map<String, dynamic> json) {
    return FederatedUpdate(
      deviceId: json['deviceId'],
      gradients: List<double>.from(json['gradients']),
      accuracy: json['accuracy'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      type: UpdateType.values.firstWhere((e) => e.name == json['type']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'gradients': gradients,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }
}

class TrainingMetrics {
  final String deviceId;
  final int epoch;
  final double loss;
  final double accuracy;
  final DateTime timestamp;
  
  TrainingMetrics({
    required this.deviceId,
    required this.epoch,
    required this.loss,
    required this.accuracy,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'epoch': epoch,
      'loss': loss,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum UpdateType { gradient, aggregated, metrics }