import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:on_device_training_sandbox/models/training_metric.dart';
import 'package:on_device_training_sandbox/training/trainer.dart';
import 'package:on_device_training_sandbox/models/model_architecture.dart';
import 'package:on_device_training_sandbox/models/training_config.dart';
import 'package:on_device_training_sandbox/utils/dataset_loader.dart';
import 'package:on_device_training_sandbox/utils/model_exporter.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late MobileTrainer _trainer;
  List<TrainingMetric> _metrics = [];
  bool _isTraining = false;
  String _status = 'Ready';
  double _progress = 0.0;
  dynamic _trainingResult;

  @override
  void initState() {
    super.initState();
    _trainer = MobileTrainer();
  }

  void _startTraining() async {
    if (_isTraining) return;

    setState(() {
      _isTraining = true;
      _status = 'Loading dataset...';
      _metrics = [];
    });

    try {
      // Load dataset
      final dataset = await DatasetLoader.loadMNISTDataset(
        maxSamples: 1000,
        training: true,
      );
      final preprocessed = DatasetLoader.preprocess(dataset);

      // Configure model
      final architecture = ModelArchitecture(layers: [784, 128, 64, 10]);
      final config = TrainingConfig(
        epochs: 10,
        batchSize: 32,
        learningRate: 0.01,
        useArmOptimizations: true,
      );

      setState(() {
        _status = 'Training...';
      });

      // Train model
      final result = await _trainer.trainModel(
        dataset: preprocessed,
        architecture: architecture,
        config: config,
      );

      setState(() {
        _metrics = result.metrics;
        _trainingResult = result;
        _progress = 1.0;
        _status = 'Training complete!';
        _isTraining = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Final Accuracy: ${(result.finalAccuracy * 100).toStringAsFixed(2)}%'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isTraining = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopTraining() {
    _trainer.pauseTraining();
    setState(() {
      _isTraining = false;
      _status = 'Stopped';
    });
  }

  void _exportModel() async {
    if (_trainingResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No trained model to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _status = 'Exporting model...');
      
      final modelName = 'trained_model_${DateTime.now().millisecondsSinceEpoch}';
      
      final tflitePath = await ModelExporter.exportToTFLite(
        weights: _trainingResult.weights,
        modelName: modelName,
      );
      
      final configPath = await ModelExporter.exportConfig(
        weights: _trainingResult.weights,
        modelName: modelName,
        metadata: {
          'final_accuracy': _trainingResult.finalAccuracy,
          'training_time_ms': _trainingResult.trainingTime.inMilliseconds,
          'epochs_trained': _trainingResult.metrics.length,
        },
      );
      
      setState(() => _status = 'Model exported successfully!');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Model exported successfully!'),
              Text('TFLite: ${tflitePath.split('/').last}'),
              Text('Config: ${configPath.split('/').last}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Export failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Model'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _isTraining 
                        ? LinearProgressIndicator(value: null)  // Indeterminate when training
                        : LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 12),
                    Text(
                      'Progress: ${(_progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loss chart
            if (_metrics.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Loss',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData:
                                FlGridData(show: true, drawVerticalLine: true),
                            titlesData: FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _metrics
                                    .asMap()
                                    .entries
                                    .map((e) =>
                                        FlSpot(e.key.toDouble(), e.value.loss))
                                    .toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Accuracy chart
            if (_metrics.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Accuracy',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData:
                                FlGridData(show: true, drawVerticalLine: true),
                            titlesData: FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _metrics
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                        e.key.toDouble(), e.value.accuracy))
                                    .toList(),
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Metrics table
            if (_metrics.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metrics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Epoch')),
                            DataColumn(label: Text('Loss')),
                            DataColumn(label: Text('Accuracy')),
                          ],
                          rows: _metrics
                              .map(
                                (m) => DataRow(
                                  cells: [
                                    DataCell(Text(m.epoch.toString())),
                                    DataCell(
                                        Text(m.loss.toStringAsFixed(4))),
                                    DataCell(Text(
                                        '${(m.accuracy * 100).toStringAsFixed(2)}%')),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Control buttons
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTraining ? null : _startTraining,
                  icon: _isTraining 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Start Training'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isTraining ? _stopTraining : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _trainingResult != null && !_isTraining 
                      ? _exportModel 
                      : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Export Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
