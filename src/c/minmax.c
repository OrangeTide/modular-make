/* Portable C fallback for minmax_f32x4.
 * Used on architectures without a dedicated SIMD implementation.
 * On x86-64 and aarch64 the arch-specific assembly is used instead
 * (see arch/minmax_x86_64.S and arch/minmax_aarch64.S). */
#include "minmax.h"

void
minmax_f32x4(const float *in, float *out)
{
	float mn = in[0], mx = in[0];
	int i;
	for (i = 1; i < 4; i++) {
		if (in[i] < mn)
			mn = in[i];
		if (in[i] > mx)
			mx = in[i];
	}
	out[0] = mn;
	out[1] = mx;
}
