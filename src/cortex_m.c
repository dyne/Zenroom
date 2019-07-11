#include <stddef.h>
#include <stdint.h>
#include "zenroom.h"
#ifdef ARCH_CORTEX
extern unsigned int _start_heap;
// #define NULL (((void *)0))
//
//


/**  XXX Temporary proxy until these dependencies are resolved **/
int _isatty(int fd)
{
    (void)fd;
    return 0;
}

int _read(int fd, void *buf, size_t len)
{
    return -1;
}

int _write(int fd, const void *buf, size_t len)
{
    return -1;
}

int _lseek(int fd, int off, int whence)
{
    return 0;
}

int _fstat(int fd, void *st)
{
    return -1;
}

int _close(int fd)
{
    return 0;
}


void abort(void)
{
    while(1) {
        /* Panic! */
    }
}

void exit(int val)
{
	(void)val;
}

void * _sbrk(unsigned int incr)
{
    static unsigned char *heap = (unsigned char *)&_start_heap;
    void *old_heap = heap;
    if (((incr >> 2) << 2) != incr)
        incr = ((incr >> 2) + 1) << 2;

    if (heap == NULL)
		heap = (unsigned char *)&_start_heap;
	else
        heap += incr;
    return old_heap;
}

void * _sbrk_r(unsigned int incr)
{
    static unsigned char *heap = NULL;
    void *old_heap = heap;
    if (((incr >> 2) << 2) != incr)
        incr = ((incr >> 2) + 1) << 2;

    if (old_heap == NULL)
		old_heap = heap = (unsigned char *)&_start_heap;
    heap += incr;
    return old_heap;
}

extern unsigned int _stored_data;
extern unsigned int _start_data;
extern unsigned int _end_data;
extern unsigned int _start_bss;
extern unsigned int _end_bss;
extern unsigned int _end_stack;
extern unsigned int _start_heap;

#define STACK_PAINTING

static volatile unsigned int avail_mem = 0;
static unsigned int sp;

extern void main(void);
void isr_reset(void) {
    register unsigned int *src, *dst;
    src = (unsigned int *) &_stored_data;
    dst = (unsigned int *) &_start_data;
    /* Copy the .data section from flash to RAM. */
    while (dst < (unsigned int *)&_end_data) {
        *dst = *src;
        dst++;
        src++;
    }

    /* Initialize the BSS section to 0 */
    dst = &_start_bss;
    while (dst < (unsigned int *)&_end_bss) {
        *dst = 0U;
        dst++;
    }

    /* Paint the stack. */
    avail_mem = &_end_stack - &_start_heap;
    {
        asm volatile("mrs %0, msp" : "=r"(sp));
        dst = ((unsigned int *)(&_end_stack)) - (8192 / 4 ); // 32bit
        while ((unsigned int)dst < sp) {
            *dst = 0xDEADC0DE;
            dst++;
        }
    }
    /* Run the program! */
    main();
}

void isr_fault(void)
{
    /* Panic. */
    while(1) ;;
}


void isr_memfault(void)
{
    /* Panic. */
    while(1) ;;
}

void isr_busfault(void)
{
    /* Panic. */
    while(1) ;;
}

void isr_usagefault(void)
{
    /* Panic. */
    while(1) ;;
}
        

void isr_empty(void)
{
    /* Ignore the event and continue */
}



__attribute__ ((section(".isr_vector")))
void (* const IV[])(void) =
{
	(void (*)(void))(&_end_stack),
	isr_reset,                   // Reset
	isr_fault,                   // NMI
	isr_fault,                   // HardFault
	isr_memfault,                // MemFault
	isr_busfault,                // BusFault
	isr_usagefault,              // UsageFault
	0, 0, 0, 0,                  // 4x reserved
	isr_empty,                   // SVC
	isr_empty,                   // DebugMonitor
	0,                           // reserved
	isr_empty,                   // PendSV
	isr_empty,                   // SysTick

    isr_empty,                     // GPIO Port A
    isr_empty,                     // GPIO Port B
    isr_empty,                     // GPIO Port C
    isr_empty,                     // GPIO Port D
    isr_empty,                     // GPIO Port E
    isr_empty,                     // UART0 Rx and Tx
    isr_empty,                     // UART1 Rx and Tx
    isr_empty,                     // SSI0 Rx and Tx
    isr_empty,                     // I2C0 Master and Slave
    isr_empty,                     // PWM Fault
    isr_empty,                     // PWM Generator 0
    isr_empty,                     // PWM Generator 1
    isr_empty,                     // PWM Generator 2
    isr_empty,                     // Quadrature Encoder 0
    isr_empty,                     // ADC Sequence 0
    isr_empty,                     // ADC Sequence 1
    isr_empty,                     // ADC Sequence 2
    isr_empty,                     // ADC Sequence 3
    isr_empty,                     // Watchdog timer
    isr_empty,                     // Timer 0 subtimer A
    isr_empty,                     // Timer 0 subtimer B
    isr_empty,                     // Timer 1 subtimer A
    isr_empty,                     // Timer 1 subtimer B
    isr_empty,                     // Timer 2 subtimer A
    isr_empty,                     // Timer 3 subtimer B
    isr_empty,                     // Analog Comparator 0
    isr_empty,                     // Analog Comparator 1
    isr_empty,                     // Analog Comparator 2
    isr_empty,                     // System Control (PLL, OSC, BO)
    isr_empty,                     // FLASH Control
    isr_empty,                     // GPIO Port F
    isr_empty,                     // GPIO Port G
    isr_empty,                     // GPIO Port H
    isr_empty,                     // UART2 Rx and Tx
    isr_empty,                     // SSI1 Rx and Tx
    isr_empty,                     // Timer 3 subtimer A
    isr_empty,                     // Timer 3 subtimer B
    isr_empty,                     // I2C1 Master and Slave
    isr_empty,                     // Quadrature Encoder 1
    isr_empty,                     // CAN0
    isr_empty,                     // CAN1
    isr_empty,                     // CAN2
    isr_empty,                     // Ethernet
    isr_empty,                     // Hibernate


};

// 20k i/o buffer
#define ZEN_BUF_LEN 20480
static const char zenroom_test_code[] = "print('Hello, world!\r\n')";
// char __attribute__((section(".zenmem")))
char zen_stderr[ZEN_BUF_LEN];
// char __attribute__((section(".zenmem")))
char zen_stdout[ZEN_BUF_LEN];

/* TODO: Initialize target-specific rng to generate initial randomness */

static const char PUF_RNG[] = "uvVu3thQapaKX1Nso6ElSkzZafq3kHCG";

void main(void)
{
    zenroom_exec_rng_tobuf(zenroom_test_code, NULL, NULL, NULL, 1,
                           zen_stdout, ZEN_BUF_LEN,
                           zen_stderr, ZEN_BUF_LEN,
                           PUF_RNG, 32);
}


#endif


