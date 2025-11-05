import 'dart:io';

class ThermalController {
  Future<ThermalState> getCurrentState() async {
    try {
      // Read thermal zone temperature
      final result = await Process.run('cat', ['/sys/class/thermal/thermal_zone0/temp']);
      final temp = int.parse(result.stdout.toString().trim()) / 1000; // Convert to Celsius

      if (temp < 60) return ThermalState.nominal;
      if (temp < 70) return ThermalState.fair;
      if (temp < 80) return ThermalState.serious;
      return ThermalState.critical;
    } catch (e) {
      return ThermalState.nominal; // Default to nominal if can't read
    }
  }

  Future<void> adjustTrainingPerformance(ThermalState state) async {
    // This logic is currently handled inside ARMOptimizer.shouldThrottle
    // For now, this can be a placeholder.
    print("Adjusting performance for state: $state");
  }
}

enum ThermalState { nominal, fair, serious, critical }
