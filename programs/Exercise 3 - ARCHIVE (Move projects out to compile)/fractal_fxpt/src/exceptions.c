#include <stdio.h>
#include <stdint.h>
#include <perf.h>
#include <swap.h>
#include <cache.h>
#include <stdint.h>

#include <exceptions.h>
#include <exception.h>
#include <spr.h>
#include <vga.h>


/* -------------------- Exo 2.4 : Exception vectors -------------------- */
void allignment_exception_handler(void) {
    puts("My alignment exception handler!");
}

/* -------------------- Exo 2.5 : System calls -------------------- */
void system_call_handler(void) {
    uint32_t epc = SPR_READ(SPR_EPC);

    uint32_t instruction = *(volatile uint32_t *)(epc);
    uint32_t previous_instruction = *(volatile uint32_t *)(epc - 4);
    uint32_t syscall_number = previous_instruction & 0xFFFF; // Recover the syscall number

    //printf("EPC = 0x%08x\n", epc);
    //printf("Instruction at EPC = 0x%08x\n", instruction);
    //printf("Instruction at EPC - 4 = 0x%08x\n", previous_instruction);
    printf("Syscall number = 0x%04x\n", syscall_number);

    // Clear VGA screen for syscall 0xE0
    if (syscall_number == 0xE0) {
        vga_clear();
    }
}

void init_my_exceptions(void) {
    //_vectors[EXCEPTION_ALLIGNMENT_EXCEPTION] = my_alignment_exception_handler;
    //_vectors[EXCEPTION_SYSTEM_CALL] = my_syscall_exception_handler;
}


