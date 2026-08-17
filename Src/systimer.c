#include <stdint.h>

#include "gd32vw55x.h"
#include "systimer.h"

volatile uint32_t g_systimer_ticks = 0U;

void systimer_init_1ms(void)
{
    SysTimer_SetControlValue(SysTimer_MTIMECTL_CMPCLREN_Msk);
    SysTimer_SetCompareValue(SystemCoreClock / 4000U);

    __ECLIC_SetTrigIRQ(CLIC_INT_TMR, ECLIC_POSTIVE_EDGE_TRIGGER);
    ECLIC_ClearPendingIRQ(CLIC_INT_TMR);
    eclic_irq_enable(CLIC_INT_TMR, 0U, 0U);
}

uint32_t systimer_millis(void)
{
    return g_systimer_ticks;
}

/* La ISR solo mantiene la base de tiempo; no ejecuta tareas. */
void eclic_mtip_handler(void)
{
    ECLIC_ClearPendingIRQ(CLIC_INT_TMR);
    g_systimer_ticks++;
}
