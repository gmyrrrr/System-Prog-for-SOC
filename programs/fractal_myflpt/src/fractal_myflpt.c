#include "fractal_myflpt.h"
#include <swap.h>
#include <stdio.h>

//! \brief  Mandelbrot fractal point calculation function
//! \param  cx    x-coordinate
//! \param  cy    y-coordinate
//! \param  n_max maximum number of iterations
//! \return       number of performed iterations at coordinate (cx, cy)
uint16_t calc_mandelbrot_point_soft(flpt_1_27_4 cx, flpt_1_27_4 cy, uint16_t n_max) {
  flpt_1_27_4 x = cx;
  flpt_1_27_4 y = cy;
  uint16_t n = 0;
  flpt_1_27_4 xx, yy, two_xy;
  const flpt_1_27_4 FOUR = float_to_flpt(4.0); 

  while (n < n_max) {
    // Before the break
    ++n;

    // Products kept in int64_t
    xx = flpt_mul(x, x);
    yy = flpt_mul(y, y);

    // Escape test before converting back to fxpt_4_28
    if (flpt_is_greater_or_equal(flpt_add(xx, yy), FOUR)) break;

    // Products (times 2) kept in int64_t 
    two_xy = flpt_mul(x, y);
    two_xy = flpt_add(two_xy, two_xy);

    x = flpt_add(flpt_sub(xx, yy), cx);
    y = flpt_add(two_xy, cy);
  }
  return n;
}

flpt_1_27_4 float_to_flpt(float x) {
  if (x == 0.0f) return 0;

  int sign = (x < 0.0f) ? 1 : 0;
  if (sign) x = -x;

  int exponent = 0;

  // For numbers greater than or equal to 2.0, divide by 2 until the number is in the range [1.0, 2.0)
  while (x >= 2.0f) {
      x /= 2.0f;
      exponent++;
  }

  // For numbers less than 1.0, multiply by 2 until the number is in the range [1.0, 2.0)
  while (x < 1.0f) {
      x *= 2.0f;
      exponent--;
  }

  // Implict leading 1 
  float mantissa = x - 1.0f;

  exponent += EXPONENT_BIAS;

  flpt_1_27_4 result = ((uint32_t)sign << SIGN_SHIFT) | ((uint32_t)(mantissa * (1U << NBR_MANTISSA_BITS)) << MANTISSA_SHIFT) | ((uint32_t)exponent & EXPONENT_MASK);

  return result;
}

flpt_1_27_4 flpt_add(flpt_1_27_4 a, flpt_1_27_4 b){
  if (a == 0) return b;
  if (b == 0) return a;

  signed int sign_a = (a & SIGN_MASK) >> SIGN_SHIFT;
  signed int sign_b = (b & SIGN_MASK) >> SIGN_SHIFT;
  signed int exponent_a = (a & EXPONENT_MASK) >> EXPONENT_SHIFT;
  signed int exponent_b = (b & EXPONENT_MASK) >> EXPONENT_SHIFT;

  // With implicit leading 1 => (-1)^s * 1.m * 2^(E-8)
  signed int mantissa_a = ((a & MANTISSA_MASK) >> MANTISSA_SHIFT) | (1U << NBR_MANTISSA_BITS);
  signed int mantissa_b = ((b & MANTISSA_MASK) >> MANTISSA_SHIFT) | (1U << NBR_MANTISSA_BITS);

  if (exponent_a > exponent_b) {
    mantissa_b >>= (exponent_a - exponent_b);
    exponent_b = exponent_a;
  } else if (exponent_b > exponent_a) {
    mantissa_a >>= (exponent_b - exponent_a);
    exponent_a = exponent_b;
  }

  signed int result_mantissa = (sign_a ? -mantissa_a : mantissa_a) + (sign_b ? -mantissa_b : mantissa_b);
  signed int result_sign = (result_mantissa < 0);

  // Work with absolute mantissa
  if (result_sign) result_mantissa = -result_mantissa;
  if (result_mantissa == 0) return 0;

  // Overflow
  if (result_mantissa >= (1U << (NBR_MANTISSA_BITS + 1))) {
    result_mantissa >>= 1;
    exponent_a++;
  }

  // Underflow
  while (result_mantissa < (1U << NBR_MANTISSA_BITS)) {
    if (exponent_a <= 0)
        return 0;

    result_mantissa <<= 1;
    exponent_a--;
  }

  if (exponent_a > 15) {return ((uint32_t)result_sign << SIGN_SHIFT) | MANTISSA_MASK | EXPONENT_MASK;}

  // Remove implicit leading 1 
  uint32_t stored_mantissa = result_mantissa & ((1U << NBR_MANTISSA_BITS) - 1U);

  return (result_sign << SIGN_SHIFT) | ((uint32_t)stored_mantissa << MANTISSA_SHIFT) | (exponent_a & EXPONENT_MASK);
}

flpt_1_27_4 flpt_sub(flpt_1_27_4 a, flpt_1_27_4 b){
  if (b == 0) return a;
  return flpt_add(a, (b ^ SIGN_MASK));
}

flpt_1_27_4 flpt_mul(flpt_1_27_4 a, flpt_1_27_4 b){
  if (a == 0 || b == 0) return 0;

  signed int sign_a = (a & SIGN_MASK) >> SIGN_SHIFT;
  signed int sign_b = (b & SIGN_MASK) >> SIGN_SHIFT;
  signed int exponent_a = (a & EXPONENT_MASK) >> EXPONENT_SHIFT;
  signed int exponent_b = (b & EXPONENT_MASK) >> EXPONENT_SHIFT;

  // With implicit leading 1 => (-1)^s * 1.m * 2^(E-8)
  signed int mantissa_a = ((a & MANTISSA_MASK) >> MANTISSA_SHIFT) | (1U << NBR_MANTISSA_BITS);
  signed int mantissa_b = ((b & MANTISSA_MASK) >> MANTISSA_SHIFT) | (1U << NBR_MANTISSA_BITS);

  signed int result_sign = sign_a ^ sign_b;
  signed int result_exponent = exponent_a + exponent_b - EXPONENT_BIAS;
  signed long long result_mantissa = (long long)mantissa_a * mantissa_b;

  // Normalize the result
  if (result_mantissa >= (1LL << (2 * NBR_MANTISSA_BITS + 1))) {
    result_mantissa >>= 1;
    result_exponent++;
  }

  // Exponent underflow
  if (result_exponent < 0) {
    return 0;
  }

  // Exponent overflow
  if (result_exponent > 15) {
    // Handle overflow (return max value)
    return (result_sign << SIGN_SHIFT) | ((1U << NBR_MANTISSA_BITS) - 1U) << MANTISSA_SHIFT | (EXPONENT_MASK);
  }

  // Remove implicit leading 1 
  uint32_t stored_mantissa = (result_mantissa >> NBR_MANTISSA_BITS) & ((1U << NBR_MANTISSA_BITS) - 1U);

  return (result_sign << SIGN_SHIFT) | ((uint32_t)stored_mantissa << MANTISSA_SHIFT) | (result_exponent & EXPONENT_MASK);
}

bool flpt_is_greater_or_equal(flpt_1_27_4 a, flpt_1_27_4 b) {

  // Equal values
  if (a == b) return true;

  // Zero special case
  if (a == 0) return (b & SIGN_MASK) != 0;
  if (b == 0) return (a & SIGN_MASK) == 0;

  signed int sign_a = (a & SIGN_MASK) >> SIGN_SHIFT;
  signed int sign_b = (b & SIGN_MASK) >> SIGN_SHIFT;

  signed int exponent_a = (a & EXPONENT_MASK) >> EXPONENT_SHIFT;
  signed int exponent_b = (b & EXPONENT_MASK) >> EXPONENT_SHIFT;

  signed int mantissa_a = (a & MANTISSA_MASK) >> MANTISSA_SHIFT;
  signed int mantissa_b = (b & MANTISSA_MASK) >> MANTISSA_SHIFT;

  // Different signs
  if (sign_a != sign_b) {
    return sign_a < sign_b;
  }

  // Different exponents
  if (exponent_a != exponent_b) {
    if (!sign_a)
      return exponent_a > exponent_b;
    else
      return exponent_a < exponent_b;
  }

  // Compare mantissas
  if (!sign_a)
    return mantissa_a > mantissa_b;
  else
    return mantissa_a < mantissa_b;
}


//! \brief  Map number of performed iterations to black and white
//! \param  iter  performed number of iterations
//! \param  n_max maximum number of iterations
//! \return       colour
rgb565 iter_to_bw(uint16_t iter, uint16_t n_max) {
  if (iter == n_max) {
    return 0x0000;
  }
  return 0xffff;
}


//! \brief  Map number of performed iterations to grayscale
//! \param  iter  performed number of iterations
//! \param  n_max maximum number of iterations
//! \return       colour
rgb565 iter_to_grayscale(uint16_t iter, uint16_t n_max) {
  if (iter == n_max) {
    return 0x0000;
  }
  uint16_t brightness = iter & 0xf;
  return swap_u16(((brightness << 12) | ((brightness << 7) | brightness<<1)));
}


//! \brief Calculate binary logarithm for unsigned integer argument x
//! \note  For x equal 0, the function returns -1.
int ilog2(unsigned x) {
  if (x == 0) return -1;
  int n = 1;
  if ((x >> 16) == 0) { n += 16; x <<= 16; }
  if ((x >> 24) == 0) { n += 8; x <<= 8; }
  if ((x >> 28) == 0) { n += 4; x <<= 4; }
  if ((x >> 30) == 0) { n += 2; x <<= 2; }
  n -= x >> 31;
  return 31 - n;
}


//! \brief  Map number of performed iterations to a colour
//! \param  iter  performed number of iterations
//! \param  n_max maximum number of iterations
//! \return colour in rgb565 format little Endian (big Endian for openrisc)
rgb565 iter_to_colour(uint16_t iter, uint16_t n_max) {
  if (iter == n_max) {
    return 0x0000;
  }
  uint16_t brightness = (iter&1)<<4|0xF;
  uint16_t r = (iter & (1 << 3)) ? brightness : 0x0;
  uint16_t g = (iter & (1 << 2)) ? brightness : 0x0;
  uint16_t b = (iter & (1 << 1)) ? brightness : 0x0;
  return swap_u16(((r & 0x1f) << 11) | ((g & 0x1f) << 6) | ((b & 0x1f)));
}

rgb565 iter_to_colour1(uint16_t iter, uint16_t n_max) {
  if (iter == n_max) {
    return 0x0000;
  }
  uint16_t brightness = ((iter&0x78)>>2)^0x1F;
  uint16_t r = (iter & (1 << 2)) ? brightness : 0x0;
  uint16_t g = (iter & (1 << 1)) ? brightness : 0x0;
  uint16_t b = (iter & (1 << 0)) ? brightness : 0x0;
  return swap_u16(((r & 0xf) << 12) | ((g & 0xf) << 7) | ((b & 0xf)<<1));
}

//! \brief  Draw fractal into frame buffer
//! \param  width  width of frame buffer
//! \param  height height of frame buffer
//! \param  cfp_p  pointer to fractal function
//! \param  i2c_p  pointer to function mapping number of iterations to colour
//! \param  cx_0   start x-coordinate
//! \param  cy_0   start y-coordinate
//! \param  delta  increment for x- and y-coordinate
//! \param  n_max  maximum number of iterations
void draw_fractal(rgb565 *fbuf, int width, int height,
                  calc_frac_point_p cfp_p, iter_to_colour_p i2c_p,
                  flpt_1_27_4 cx_0, flpt_1_27_4 cy_0, flpt_1_27_4 delta, uint16_t n_max) {
  rgb565 *pixel = fbuf;
  flpt_1_27_4 cy = cy_0;
  for (int k = 0; k < height; ++k) {
    flpt_1_27_4 cx = cx_0;
    for(int i = 0; i < width; ++i) {
      uint16_t n_iter = (*cfp_p)(cx, cy, n_max);
      rgb565 colour = (*i2c_p)(n_iter, n_max);
      *(pixel++) = colour;
      cx = flpt_add(cx, delta);
    }
    cy = flpt_add(cy, delta);
  }
}