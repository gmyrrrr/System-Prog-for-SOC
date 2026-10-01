#ifndef FRACTAL_MYFLPT_H
#define FRACTAL_MYFLPT_H

#include <stdint.h>
#include <stdbool.h>

//-------------CODE ADDED-----------//
//! New type using 1 signed bit 4 exponent bit and 27 mantisse bits
typedef uint32_t flpt_1_27_4;

#define NBR_MANTISSA_BITS  27
#define NBR_EXPONENT_BITS   4
#define EXPONENT_BIAS       8

#define SIGN_SHIFT          31
#define MANTISSA_SHIFT      4
#define EXPONENT_SHIFT      0

#define SIGN_MASK           (1U << SIGN_SHIFT)
#define MANTISSA_MASK       (((1U << NBR_MANTISSA_BITS) - 1U) << MANTISSA_SHIFT)
#define EXPONENT_MASK       ((1U << NBR_EXPONENT_BITS) - 1U)

flpt_1_27_4 float_to_flpt(float x);

// New operators for floating-point arithmetic
flpt_1_27_4 flpt_add(flpt_1_27_4 a, flpt_1_27_4 b);
flpt_1_27_4 flpt_sub(flpt_1_27_4 a, flpt_1_27_4 b);
flpt_1_27_4 flpt_mul(flpt_1_27_4 a, flpt_1_27_4 b);
bool flpt_is_greater_or_equal(flpt_1_27_4 a, flpt_1_27_4 b);

//----------------------------------//

//! Colour type (5-bit red, 6-bit green, 5-bit blue)
typedef uint16_t rgb565;

//! \brief Pointer to fractal point calculation function
typedef uint16_t (*calc_frac_point_p)(flpt_1_27_4 cx, flpt_1_27_4 cy, uint16_t n_max);

uint16_t calc_mandelbrot_point_soft(flpt_1_27_4 cx, flpt_1_27_4 cy, uint16_t n_max);

//! Pointer to function mapping iteration to colour value
typedef rgb565 (*iter_to_colour_p)(uint16_t iter, uint16_t n_max);

rgb565 iter_to_bw(uint16_t iter, uint16_t n_max);
rgb565 iter_to_grayscale(uint16_t iter, uint16_t n_max);
rgb565 iter_to_colour(uint16_t iter, uint16_t n_max);

void draw_fractal(rgb565 *fbuf, int width, int height,
                  calc_frac_point_p cfp_p, iter_to_colour_p i2c_p,
                  flpt_1_27_4 cx_0, flpt_1_27_4 cy_0, flpt_1_27_4 delta, uint16_t n_max);

#endif // FRACTAL_MYFLPT_H
