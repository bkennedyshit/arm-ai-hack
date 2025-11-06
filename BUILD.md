# ARM AI Training Lab - Build & Deployment Guide

## Project Overview

ARM AI Training Lab is a revolutionary Flutter application that enables **complete neural network training directly on ARM mobile devices** using NEON SIMD optimizations. Unlike existing mobile AI apps that only perform inference, this platform allows users to train custom neural networks on their device.

## Prerequisites

### Required Tools
- **Flutter SDK 3.0+** - Download from [flutter.dev](https://flutter.dev)
- **Android SDK** - API level 26+ (Android 8.0+)
- **Android NDK** - For C++ native code compilation
- **CMake 3.18+** - For building C++ code
- **Java Development Kit (JDK) 11+** - For Android build tools

### System Requirements
- **OS**: macOS, Linux, or Windows with WSL2
- **RAM**: 8GB minimum
- **Storage**: 10GB for SDKs and tools
- **Target Device**: ARM Cortex-A53 or newer (2015+)

## Setup Instructions

### 1. Install Flutter

```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Install Android Development Tools

```bash
# Install Android SDK (if not already installed)
# Via Android Studio or command line tools

# Set ANDROID_SDK_ROOT
export ANDROID_SDK_ROOT=~/Android/Sdk

# Install specific API level (26+)
sdkmanager "platforms;android-31" "build-tools;31.0.0"

# Install Android NDK
sdkmanager "ndk;25.1.8937393"
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/25.1.8937393

# Verify
flutter doctor -v
```

### 3. Clone and Setup Project

```bash
# Clone the repository
git clone https://github.com/bkennedyshit/arm-ai-hack.git
cd arm-ai-hack

# Get Flutter dependencies
flutter pub get

# Verify setup
flutter doctor
```

## Building the Project

### Development Build (Debug)

```bash
# Build and run on connected device
flutter run

# Or build debug APK
flutter build apk --debug

# Run with verbose output
flutter run -v
```

### Production Build (Release)

```bash
# Build optimized release APK
flutter build apk --release

# Generate APK split by ABI for smaller downloads
flutter build apk --target-platform=android-arm64 --split-per-abi --release

# Output: build/app/outputs/apk/release/app-release.apk
```

### Build Options

```bash
# Build for specific architecture
flutter build apk --target-platform=android-arm64

# Include split debug symbols for better crash reports
flutter build apk --split-debug-info=symbols --release

# Build with specific flavor (if configured)
flutter build apk --flavor production --release
```

## Running Tests

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/training_test.dart

# Run with verbose output
flutter test -v

# Run with code coverage
flutter test --coverage
```

### Widget Tests

```bash
# Run widget tests
flutter test --tags widget

# Run integration tests (requires device)
flutter drive --target=test_driver/app.dart
```

## Deployment

### Installing on Android Device

```bash
# Connected via USB with debugging enabled
flutter install

# Or install APK directly
adb install build/app/outputs/apk/release/app-release.apk

# Verify installation
adb shell pm list packages | grep training_sandbox
```

### Device Requirements

- **Minimum OS**: Android 8.0 (API 26)
- **Preferred**: Android 10+ (API 29+)
- **RAM**: 2GB minimum, 4GB+ recommended
- **Storage**: 100MB for app + 500MB working space
- **ARM CPU**: Cortex-A53 or newer

### Performance Validation

```bash
# Monitor performance during training
adb shell perfprofd start

# Check thermal state
adb shell cat /sys/class/thermal/thermal_zone0/temp

# Monitor memory usage
adb shell dumpsys meminfo com.trainingSandbox.app

# Check CPU usage
adb shell top -b -n 1 | grep com.trainingSandbox.app
```

## ARM NEON Optimization Build

The project includes native C++ code compiled with ARM NEON SIMD instructions for maximum performance.

### Build C++ Components

```bash
# Automatic (included in flutter build)
flutter build apk

# Manual CMake build (for development)
cd android/app/src/main/cpp
mkdir -p build
cd build
cmake ..
make
```

### Verify NEON Compilation

```bash
# Check compiled library
objdump -d android/app/src/main/jniLibs/arm64-v8a/libneon_ops.so | grep -i "neon\|simd"

# Or use readelf
readelf -A android/app/src/main/jniLibs/arm64-v8a/libneon_ops.so | grep -i "neon"
```

## Troubleshooting

### Common Build Issues

**Issue: NDK not found**
```bash
# Solution: Set NDK path
export ANDROID_NDK_ROOT=~/Android/Sdk/ndk/25.1.8937393
flutter clean
flutter pub get
flutter build apk
```

**Issue: C++ compilation errors**
```bash
# Clean C++ build artifacts
cd android
./gradlew clean
cd ..
flutter build apk --verbose
```

**Issue: OutOfMemory errors during build**
```bash
# Increase Gradle heap size
export ORG_GRADLE_PROJECT_org_gradle_jvmargs="-Xmx4096m"
flutter build apk --release
```

### Runtime Issues

**Issue: Model training is slow**
- Verify ARM NEON is enabled: check device CPU info
- Reduce batch size in training config
- Monitor thermal state and allow cooling

**Issue: App crashes with "Out of memory"**
- Reduce dataset size
- Lower batch size
- Reduce model complexity
- Clear device cache: `adb shell pm clear com.trainingSandbox.app`

**Issue: Thermal throttling**
- Normal behavior on sustained training
- App automatically reduces batch size
- Consider training on devices with better thermal design

## Performance Benchmarking

### Running Benchmarks

```bash
# Execute benchmark suite
flutter test benchmarks/training_speed.dart

# Profile with Dart DevTools
flutter run --profile
# Then connect to http://localhost:9100 in browser

# CPU profiling on device
adb shell cmd package set-debug-app --persistent com.trainingSandbox.app
flutter run --profile -v
```

### Expected Performance

| Metric | Target | Notes |
|--------|--------|-------|
| Training Speed | 10+ samples/sec | On ARM Cortex-A53 |
| NEON Speedup | 2.5x | vs standard implementation |
| Memory Usage | <500MB peak | During training |
| Model Export | <2 seconds | For typical models |
| Inference Speed | 3-8ms | Per sample |

## Development Workflow

### Hot Reload

```bash
# Development mode with hot reload
flutter run

# Type 'r' to reload, 'R' to restart
# Changes to Dart code reload immediately
```

### Debugging

```bash
# Enable debug logging
flutter run --verbose

# Attach debugger
flutter attach

# Debug on real device
flutter run -v --debug

# Use DevTools for advanced debugging
dart devtools
```

### Code Quality

```bash
# Run linter
flutter analyze

# Format code
flutter format lib/ test/

# Check for issues
dart fix --dry-run lib/

# Apply fixes
dart fix --apply lib/
```

## Publishing (Optional)

### To Google Play Store

```bash
# Generate signing key (one-time)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure signing in android/app/build.gradle
# Build signed APK
flutter build apk --release
flutter build appbundle --release

# Upload to Play Console
# Visit https://play.google.com/console/
```

## Project Structure

```
arm-ai-hack/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── training_screen.dart
│   │   ├── tutorial_screen.dart
│   │   └── dataset_screen.dart
│   ├── models/                   # Data models
│   │   ├── model_architecture.dart
│   │   ├── training_data.dart
│   │   ├── training_metric.dart
│   │   └── tensor.dart
│   ├── training/                 # ML training logic
│   │   ├── trainer.dart
│   │   ├── arm_optimizer.dart
│   │   ├── thermal_controller.dart
│   │   └── optimizer.dart
│   └── utils/                    # Utilities
│       ├── dataset_loader.dart
│       └── model_exporter.dart
├── android/
│   └── app/src/main/cpp/
│       ├── neon_ops.cpp          # ARM NEON optimizations
│       └── CMakeLists.txt        # C++ build config
├── test/                         # Test files
│   └── training_test.dart
├── pubspec.yaml                  # Dependencies
└── README.md                      # Project documentation
```

## Key Features

✅ **On-Device Training** - Complete training loop on ARM  
✅ **ARM NEON SIMD** - 2.5x faster matrix operations  
✅ **Real-Time Visualization** - Live loss curves and accuracy charts  
✅ **Thermal Management** - Auto-throttle under heat stress  
✅ **Model Export** - TFLite and ONNX formats  
✅ **Educational** - Interactive ML concepts tutorials  
✅ **Privacy-First** - All data stays on device  
✅ **Cross-Compatible** - Android 8.0+, ARM Cortex-A53+  

## Support & Resources

- **Flutter Docs**: https://flutter.dev/docs
- **ARM NEON Guide**: https://developer.arm.com/documentation/dui0473/latest/
- **Android NDK**: https://developer.android.com/ndk
- **TensorFlow Lite**: https://www.tensorflow.org/lite

## License

MIT License - See LICENSE file for details

## Contributing

We welcome contributions! Please see CONTRIBUTING.md for guidelines.

---

**Happy Training! 🚀**
