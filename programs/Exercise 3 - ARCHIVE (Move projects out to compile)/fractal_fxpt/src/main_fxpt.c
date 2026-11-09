#include "fractal_fxpt.h"
#include "swap.h"
#include "vga.h"
#include <stddef.h>
#include <stdio.h>
#ifdef __OR1300__
#include "perf.h"
#include "cache.h"
#include <exceptions.h>
#include <exception.h>
#endif

// Constants describing the output device
const int SCREEN_WIDTH = 512;   //!< screen width
const int SCREEN_HEIGHT = 512;  //!< screen height

// Constants describing the initial view port on the fractal function
const fxpt_4_28 FRAC_WIDTH = fxpt_4_28(3.0);    //!< default fractal width (3.0 in Q4.28)
const fxpt_4_28 CX_0       = fxpt_4_28(-2.0);   //!< default start x-coordinate (-2.0 in Q4.28)
const fxpt_4_28 CY_0       = fxpt_4_28(-1.5);   //!< default start y-coordinate (-1.5 in Q4.28)
const uint16_t N_MAX = 64;                       //!< maximum number of iterations

int main() {
   init_my_exceptions(); 

   /* -------------------- Exo 2.4 : Exception vectors -------------------- */
   uintptr_t address = 0x100; // Use 0x101 to have an alignment error
   int *addr = (int *)address;
   int data;

   //printf("Reading address: 0x%08lx\n", (unsigned long)address);
   asm volatile ("l.lwz %[d], 0(%[s])" : [d] "=r" (data) : [s] "r" (addr) : "memory");

   /* -------------------- Exo 2.5 : System calls   -------------------- */
   //SYSCALL(0xAA);  // Debug syscall
   //SYSCALL(0xE0);  // Clear VGA screen

   volatile unsigned int *vga = (unsigned int *) 0x50000020;
   volatile unsigned int reg, hi;
   rgb565 frameBuffer[SCREEN_WIDTH*SCREEN_HEIGHT];
   fxpt_4_28 delta = FRAC_WIDTH / SCREEN_WIDTH;
   int i;
   vga_clear();
   printf("Starting drawing a fractal\n");

#ifdef __OR1300__
   /* Configure and enable caches */
   icache_write_cfg(CACHE_DIRECT_MAPPED | CACHE_SIZE_8K | CACHE_REPLACE_FIFO);
   dcache_write_cfg(CACHE_FOUR_WAY | CACHE_SIZE_8K | CACHE_REPLACE_LRU | CACHE_WRITE_BACK);
   icache_enable(1);
   dcache_enable(1);
#endif

   vga[0] = swap_u32(SCREEN_WIDTH);
   vga[1] = swap_u32(SCREEN_HEIGHT);
   vga[2] = swap_u32(1);
   vga[3] = swap_u32((unsigned int)&frameBuffer[0]);

   unsigned distances[] = {0};
   unsigned int nbr_of_test = sizeof(distances) / sizeof(distances[0]);
   unsigned int test = 0;

   while (test < nbr_of_test) {
   
   
   #ifdef __OR1300__
      /* initialize the performance counters */
      perf_init();
      perf_set_mask(PERF_COUNTER_0, PERF_STALL_CYCLES_MASK | PERF_ICACHE_NOP_INSERTION_MASK);
      perf_set_mask(PERF_COUNTER_1, PERF_BUS_IDLE_MASK);

      /* -------------------- Exo 2.2 : Add two profiling counters ------------------------- */
      perf_set_mask(PERF_COUNTER_2, PERF_INSTRUCTION_FETCH_MASK);
      perf_set_mask(PERF_COUNTER_3, PERF_ICACHE_MISS_MASK);
      
      /* -------------------- Exo 2.3 : Memory distance -------------------- */
      perf_memdist_set(distances[test]);
   #endif

      /* Clear screen */
      for (i = 0 ; i < SCREEN_WIDTH*SCREEN_HEIGHT ; i++) frameBuffer[i]=0;


      /* Start measurement */
   #ifdef __OR1300__
      perf_start();
   #endif
      draw_fractal(frameBuffer,SCREEN_WIDTH,SCREEN_HEIGHT,&calc_mandelbrot_point_soft, &iter_to_colour,CX_0,CY_0,delta,N_MAX);
   #ifdef __OR1300__
      perf_stop();

      /* Print results */
      printf("\nMemory distance = %u\n", distances[test]);

      perf_print_cycles(PERF_COUNTER_0, "Stall cycles    ");
      perf_print_cycles(PERF_COUNTER_1, "Bus idle cycles ");
      perf_print_cycles(PERF_COUNTER_RUNTIME, "Runtime cycles  ");

      perf_print_time(PERF_COUNTER_0, "Stall time    ");
      perf_print_time(PERF_COUNTER_1, "Bus idle time ");
      perf_print_time(PERF_COUNTER_RUNTIME, "Runtime      ");

      perf_print_cycles(PERF_COUNTER_2, "Instruction cache fetches");
      perf_print_cycles(PERF_COUNTER_3, "Instruction cache misses ");

      dcache_flush();
   #endif
      test++;
   }
   printf("Done\n");
}
