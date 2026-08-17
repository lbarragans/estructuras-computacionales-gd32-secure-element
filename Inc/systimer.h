#ifndef SYSTIMER_H
#define SYSTIMER_H

#include <stdint.h>

extern volatile uint32_t g_systimer_ticks;

void systimer_init_1ms(void);
uint32_t systimer_millis(void);

#endif /* SYSTIMER_H */
