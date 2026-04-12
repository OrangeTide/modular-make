/* minmax_f32x4 -- NEON horizontal min/max of 4 floats (aarch64) */

#ifdef __APPLE__
#define FN(name) _##name
#else
#define FN(name) name
#endif

	.text
	.globl	FN(minmax_f32x4)
#ifndef __APPLE__
	.type	FN(minmax_f32x4), %function
#endif
FN(minmax_f32x4):
	ld1	{v0.4s}, [x0]		/* load 4 floats                     */
	fminv	s1, v0.4s		/* horizontal min -> s1               */
	fmaxv	s2, v0.4s		/* horizontal max -> s2               */
	str	s1, [x1]		/* out[0] = min                      */
	str	s2, [x1, #4]		/* out[1] = max                      */
	ret
#ifndef __APPLE__
	.size	FN(minmax_f32x4), . - FN(minmax_f32x4)
#endif

#ifndef __APPLE__
	.section .note.GNU-stack,"",@progbits
#endif
