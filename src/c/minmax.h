#ifndef MINMAX_H
#define MINMAX_H
#ifdef __cplusplus
extern "C" {
#endif
/* Compute min and max of four floats using SIMD when available.
 * in:  pointer to 4 floats
 * out: out[0] = min, out[1] = max */
void minmax_f32x4(const float *in, float *out);
#ifdef __cplusplus
}
#endif
#endif
