import 'dart:io';
import 'dart:typed_data';
import 'package:on_device_training_sandbox/models/model_architecture.dart';
import 'package:path_provider/path_provider.dart';

class ModelExporter {
  /// Export trained model to TensorFlow Lite format
  static Future<String> exportToTFLite({
    required ModelWeights weights,
    required String modelName,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tfliteFile = File('${appDir.path}/$modelName.tflite');

      // In a real implementation, this would use TFLite converter
      // For now, we'll create a simplified serialization
      final buffer = _serializeModel(weights);
      await tfliteFile.writeAsBytes(buffer);

      return tfliteFile.path;
    } catch (e) {
      throw Exception('Failed to export to TFLite: $e');
    }
  }

  /// Export trained model to ONNX format
  static Future<String> exportToONNX({
    required ModelWeights weights,
    required String modelName,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final onnxFile = File('${appDir.path}/$modelName.onnx');

      // In a real implementation, this would use ONNX converter
      // For now, we'll create a simplified serialization
      final buffer = _serializeModel(weights);
      await onnxFile.writeAsBytes(buffer);

      return onnxFile.path;
    } catch (e) {
      throw Exception('Failed to export to ONNX: $e');
    }
  }

  /// Export model configuration as JSON
  static Future<String> exportConfig({
    required ModelWeights weights,
    required String modelName,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final configFile = File('${appDir.path}/$modelName.json');

      final config = {
        'model_name': modelName,
        'layers': weights.shape,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };

      await configFile.writeAsString(
        _formatJson(config),
      );

      return configFile.path;
    } catch (e) {
      throw Exception('Failed to export config: $e');
    }
  }

  /// Serialize model weights to binary format
  static Uint8List _serializeModel(ModelWeights weights) {
    final buffer = BytesBuilder();

    // Magic number
    buffer.addByte(0x4D); // 'M'
    buffer.addByte(0x4C); // 'L'

    // Version
    buffer.addByte(0x01);

    // Number of layers
    buffer.add(Uint32List.fromList([weights.layers.length]));

    // Layer shapes
    for (final layer in weights.layers) {
      buffer.add(Uint32List.fromList(layer.shape));
    }

    // Layer data (simplified - just store as floats)
    for (final layer in weights.layers) {
      for (final weight in layer.data) {
        buffer.add(Float32List.fromList([weight]));
      }
    }

    return buffer.toBytes();
  }

  /// Format configuration as JSON string
  static String _formatJson(Map<String, dynamic> config) {
    final buffer = StringBuffer('{\n');

    final entries = config.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('  "${entry.key}": ');

      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is List) {
        buffer.write('[${(entry.value as List).join(', ')}]');
      } else if (entry.value is Map) {
        buffer.write('{');
        final subEntries = (entry.value as Map).entries.toList();
        for (int j = 0; j < subEntries.length; j++) {
          final subEntry = subEntries[j];
          buffer.write('"${subEntry.key}": "${subEntry.value}"');
          if (j < subEntries.length - 1) buffer.write(', ');
        }
        buffer.write('}');
      } else {
        buffer.write(entry.value);
      }

      if (i < entries.length - 1) buffer.write(',');
      buffer.write('\n');
    }

    buffer.write('}');
    return buffer.toString();
  }

  /// List exported models
  static Future<List<String>> listExportedModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();

      return files
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.tflite') ||
              f.path.endsWith('.onnx') ||
              f.path.endsWith('.json'))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete exported model
  static Future<void> deleteModel(String modelPath) async {
    try {
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete model: $e');
    }
  }
}
