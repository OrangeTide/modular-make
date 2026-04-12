/* minmax_f32x4 -- SSE horizontal min/max of 4 floats (x86-64) */

#ifdef __APPLE__
#define FN(name) _##name
#else
#define FN(name) name
#endif

#if defined(_WIN32) || defined(__CYGWIN__)
#define IN  %rcx
#define OUT %rdx
#else
#define IN  %rdi
#define OUT %rsi
#endif

	.text
	.globl	FN(minmax_f32x4)
#ifndef __APPLE__
	.type	FN(minmax_f32x4), @function
#endif
FN(minmax_f32x4):
	movups	(IN), %xmm0		/* xmm0 = {a, b, c, d}              */
	movaps	%xmm0, %xmm1		/* xmm1 = copy for max               */
	movaps	%xmm0, %xmm2
	shufps	$0x4e, %xmm2, %xmm2	/* xmm2 = {c, d, a, b}              */
	minps	%xmm2, %xmm0		/* xmm0 = {min(a,c), min(b,d), ...}  */
	maxps	%xmm2, %xmm1		/* xmm1 = {max(a,c), max(b,d), ...}  */
	movaps	%xmm0, %xmm2
	shufps	$0xb1, %xmm2, %xmm2	/* swap pairs: {min(b,d), min(a,c)}  */
	minss	%xmm2, %xmm0		/* xmm0[0] = min of all 4            */
	movaps	%xmm1, %xmm2
	shufps	$0xb1, %xmm2, %xmm2
	maxss	%xmm2, %xmm1		/* xmm1[0] = max of all 4            */
	movss	%xmm0, (OUT)		/* out[0] = min                      */
	movss	%xmm1, 4(OUT)		/* out[1] = max                      */
	ret
#ifndef __APPLE__
	.size	FN(minmax_f32x4), . - FN(minmax_f32x4)
#endif

#ifndef __APPLE__
	.section .note.GNU-stack,"",@progbits
#endif
