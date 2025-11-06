cmake_minimum_required(VERSION 3.18)

project(arm_ai_training)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ARM NEON support
set(ARM_FEATURES "-march=armv8-a+simd -mfpu=neon")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARM_FEATURES}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARM_FEATURES}")

# Add JNI header paths
include_directories(${ANDROID_NDK}/sources/android/native_app_glue)

# NEON Operations Library
add_library(neon_ops SHARED
    neon_ops.cpp
)

# Link with Android log library
target_link_libraries(neon_ops
    log
    android
)

# Set compilation flags for optimizations
target_compile_options(neon_ops PRIVATE
    -O3
    -march=armv8-a+simd
    -mfpu=neon
    -ffast-math
    -funroll-loops
)
