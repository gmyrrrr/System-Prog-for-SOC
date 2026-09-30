#include "fractal_myflpt.h"
#include "swap.h"
#include "vga.h"
#include "cache.h"
#include <stddef.h>
#include <stdio.h>

// Constants describing the output device
const int SCREEN_WIDTH = 512;   //!< screen width
const int SCREEN_HEIGHT = 512;  //!< screen height

// Constants describing the initial view port on the fractal function
const float FRAC_WDTH =  3.0;   //!< default fractal width (3.0 in Q4.28)

// Constants describing the initial view port on the fractal function
const uint16_t N_MAX = 64;    //!< maximum number of iterations

int main() {
   // Constants describing the initial view port on the fractal function
   const flpt_1_27_4 CX_0 = float_to_flpt(-2.0);      //!< default start x-coordinate (-2.0 in Q4.28)
   const flpt_1_27_4 CY_0 = float_to_flpt(-1.5);      //!< default start y-coordinate (-1.5 in Q4.28)

   volatile unsigned int *vga = (unsigned int *) 0x50000020;
   volatile unsigned int reg, hi;
   rgb565 frameBuffer[SCREEN_WIDTH*SCREEN_HEIGHT];
   flpt_1_27_4 delta = float_to_flpt(FRAC_WDTH / SCREEN_WIDTH);

   int i;
   vga_clear();
   printf("Starting drawing a fractal\n");
#ifdef __OR1300__   
   /* enable the caches */
   icache_write_cfg( CACHE_DIRECT_MAPPED | CACHE_SIZE_8K | CACHE_REPLACE_FIFO );
   dcache_write_cfg( CACHE_FOUR_WAY | CACHE_SIZE_8K | CACHE_REPLACE_LRU | CACHE_WRITE_BACK );
   icache_enable(1);
   dcache_enable(1);
#endif
   /* Enable the vga-controller's graphic mode */
   vga[0] = swap_u32(SCREEN_WIDTH);
   vga[1] = swap_u32(SCREEN_HEIGHT);
   vga[2] = swap_u32(1);
   vga[3] = swap_u32((unsigned int)&frameBuffer[0]);

   /* Clear framebuffer */
   for (i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++)
      frameBuffer[i] = 0;

   #ifdef __OR1300__
   dcache_flush();
   #endif

   asm volatile ("" ::: "memory");

   draw_fractal(frameBuffer, SCREEN_WIDTH, SCREEN_HEIGHT,
               &calc_mandelbrot_point_soft,
               &iter_to_colour,
               CX_0, CY_0, delta, N_MAX);

   asm volatile ("" ::: "memory");

   #ifdef __OR1300__
   dcache_flush();
   #endif

   printf("Done\n");
}
