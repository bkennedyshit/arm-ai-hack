#include <jni.h>
#include <arm_neon.h>
#include <android/log.h>
#include <cmath>

#define LOG_TAG "NEON_OPS"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" {

// Optimized matrix multiplication using ARM NEON SIMD
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonMatMul(JNIEnv *env, jobject thiz, 
                                           jfloatArray a, jfloatArray b, jfloatArray result,
                                           jint m, jint n, jint k) {
    jfloat *matA = env->GetFloatArrayElements(a, nullptr);
    jfloat *matB = env->GetFloatArrayElements(b, nullptr);
    jfloat *matResult = env->GetFloatArrayElements(result, nullptr);
    
    // Process 4 elements at a time using NEON
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j += 4) {
            float32x4_t sum = vdupq_n_f32(0.0f);
            
            for (int l = 0; l < k; l++) {
                float32x4_t a_vec = vdupq_n_f32(matA[i * k + l]);
                float32x4_t b_vec = vld1q_f32(&matB[l * n + j]);
                sum = vmlaq_f32(sum, a_vec, b_vec);
            }
            
            vst1q_f32(&matResult[i * n + j], sum);
        }
    }
    
    env->ReleaseFloatArrayElements(a, matA, 0);
    env->ReleaseFloatArrayElements(b, matB, 0);
    env->ReleaseFloatArrayElements(result, matResult, 0);
}

// Optimized ReLU activation using NEON
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonReLU(JNIEnv *env, jobject thiz, 
                                         jfloatArray input, jfloatArray output, jint size) {
    jfloat *in = env->GetFloatArrayElements(input, nullptr);
    jfloat *out = env->GetFloatArrayElements(output, nullptr);
    
    float32x4_t zero = vdupq_n_f32(0.0f);
    
    // Process 4 elements at a time
    int i = 0;
    for (; i <= size - 4; i += 4) {
        float32x4_t input_vec = vld1q_f32(&in[i]);
        float32x4_t result = vmaxq_f32(input_vec, zero);
        vst1q_f32(&out[i], result);
    }
    
    // Handle remaining elements
    for (; i < size; i++) {
        out[i] = fmaxf(in[i], 0.0f);
    }
    
    env->ReleaseFloatArrayElements(input, in, 0);
    env->ReleaseFloatArrayElements(output, out, 0);
}

// Optimized convolution using NEON
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonConv2D(JNIEnv *env, jobject thiz,
                                           jfloatArray input, jfloatArray kernel, jfloatArray output,
                                           jint input_h, jint input_w, jint kernel_size, jint stride) {
    jfloat *in = env->GetFloatArrayElements(input, nullptr);
    jfloat *kern = env->GetFloatArrayElements(kernel, nullptr);
    jfloat *out = env->GetFloatArrayElements(output, nullptr);
    
    int output_h = (input_h - kernel_size) / stride + 1;
    int output_w = (input_w - kernel_size) / stride + 1;
    
    for (int oh = 0; oh < output_h; oh++) {
        for (int ow = 0; ow < output_w; ow++) {
            float32x4_t sum = vdupq_n_f32(0.0f);
            
            // Convolution operation with NEON acceleration
            for (int kh = 0; kh < kernel_size; kh++) {
                for (int kw = 0; kw < kernel_size; kw += 4) {
                    int ih = oh * stride + kh;
                    int iw = ow * stride + kw;
                    
                    if (iw + 3 < input_w) {
                        float32x4_t input_vec = vld1q_f32(&in[ih * input_w + iw]);
                        float32x4_t kernel_vec = vld1q_f32(&kern[kh * kernel_size + kw]);
                        sum = vmlaq_f32(sum, input_vec, kernel_vec);
                    }
                }
            }
            
            // Sum all elements in the vector
            float result = vgetq_lane_f32(sum, 0) + vgetq_lane_f32(sum, 1) + 
                          vgetq_lane_f32(sum, 2) + vgetq_lane_f32(sum, 3);
            out[oh * output_w + ow] = result;
        }
    }
    
    env->ReleaseFloatArrayElements(input, in, 0);
    env->ReleaseFloatArrayElements(kernel, kern, 0);
    env->ReleaseFloatArrayElements(output, out, 0);
}

// Optimized gradient computation for backpropagation
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonGradientCompute(JNIEnv *env, jobject thiz,
                                                    jfloatArray gradients, jfloatArray activations,
                                                    jfloatArray weights, jfloatArray output_grad,
                                                    jint size) {
    jfloat *grad = env->GetFloatArrayElements(gradients, nullptr);
    jfloat *act = env->GetFloatArrayElements(activations, nullptr);
    jfloat *w = env->GetFloatArrayElements(weights, nullptr);
    jfloat *out_grad = env->GetFloatArrayElements(output_grad, nullptr);
    
    // Compute gradients using NEON SIMD
    for (int i = 0; i < size; i += 4) {
        float32x4_t act_vec = vld1q_f32(&act[i]);
        float32x4_t weight_vec = vld1q_f32(&w[i]);
        float32x4_t out_grad_vec = vld1q_f32(&out_grad[i]);
        
        // Gradient = activation * output_gradient
        float32x4_t gradient = vmulq_f32(act_vec, out_grad_vec);
        vst1q_f32(&grad[i], gradient);
    }
    
    env->ReleaseFloatArrayElements(gradients, grad, 0);
    env->ReleaseFloatArrayElements(activations, act, 0);
    env->ReleaseFloatArrayElements(weights, w, 0);
    env->ReleaseFloatArrayElements(output_grad, out_grad, 0);
}

// Optimized batch normalization using NEON
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonBatchNorm(JNIEnv *env, jobject thiz,
                                              jfloatArray input, jfloatArray output,
                                              jfloat mean, jfloat variance, jfloat epsilon,
                                              jint size) {
    jfloat *in = env->GetFloatArrayElements(input, nullptr);
    jfloat *out = env->GetFloatArrayElements(output, nullptr);
    
    float inv_std = 1.0f / sqrtf(variance + epsilon);
    float32x4_t mean_vec = vdupq_n_f32(mean);
    float32x4_t inv_std_vec = vdupq_n_f32(inv_std);
    
    for (int i = 0; i < size; i += 4) {
        float32x4_t input_vec = vld1q_f32(&in[i]);
        
        // Normalize: (x - mean) / std
        float32x4_t centered = vsubq_f32(input_vec, mean_vec);
        float32x4_t normalized = vmulq_f32(centered, inv_std_vec);
        
        vst1q_f32(&out[i], normalized);
    }
    
    env->ReleaseFloatArrayElements(input, in, 0);
    env->ReleaseFloatArrayElements(output, out, 0);
}

// Optimized softmax activation using NEON
JNIEXPORT void JNICALL
Java_com_trainingSandbox_NeonOps_neonSoftmax(JNIEnv *env, jobject thiz,
                                            jfloatArray input, jfloatArray output, jint size) {
    jfloat *in = env->GetFloatArrayElements(input, nullptr);
    jfloat *out = env->GetFloatArrayElements(output, nullptr);
    
    // Find maximum value for numerical stability
    float max_val = in[0];
    for (int i = 1; i < size; i++) {
        if (in[i] > max_val) max_val = in[i];
    }
    
    float32x4_t max_vec = vdupq_n_f32(max_val);
    float sum = 0.0f;
    
    // Compute exp(x - max) and sum
    for (int i = 0; i < size; i += 4) {
        float32x4_t input_vec = vld1q_f32(&in[i]);
        float32x4_t shifted = vsubq_f32(input_vec, max_vec);
        
        // Approximate exp using NEON (for speed)
        float32x4_t exp_approx = vexpq_f32(shifted);
        vst1q_f32(&out[i], exp_approx);
        
        // Sum for normalization
        sum += vgetq_lane_f32(exp_approx, 0) + vgetq_lane_f32(exp_approx, 1) +
               vgetq_lane_f32(exp_approx, 2) + vgetq_lane_f32(exp_approx, 3);
    }
    
    // Normalize by sum
    float32x4_t sum_vec = vdupq_n_f32(sum);
    for (int i = 0; i < size; i += 4) {
        float32x4_t exp_vec = vld1q_f32(&out[i]);
        float32x4_t normalized = vdivq_f32(exp_vec, sum_vec);
        vst1q_f32(&out[i], normalized);
    }
    
    env->ReleaseFloatArrayElements(input, in, 0);
    env->ReleaseFloatArrayElements(output, out, 0);
}

// Fast approximate exp function using NEON
static inline float32x4_t vexpq_f32(float32x4_t x) {
    // Fast exp approximation: e^x ≈ (1 + x/256)^256
    float32x4_t one = vdupq_n_f32(1.0f);
    float32x4_t inv256 = vdupq_n_f32(1.0f / 256.0f);
    
    float32x4_t scaled = vmulq_f32(x, inv256);
    float32x4_t base = vaddq_f32(one, scaled);
    
    // Power of 256 (8 iterations of squaring: 2^8 = 256)
    for (int i = 0; i < 8; i++) {
        base = vmulq_f32(base, base);
    }
    
    return base;
}

} // extern "C"