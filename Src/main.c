#include <stdint.h>
#include <string.h>

#include "gd32vw55x.h"
#include "secure_element_sim.h"
#include "systimer.h"

/* LED integrado de la placa. */
#define LED_GPIO_PORT          GPIOC
#define LED_GPIO_PIN           GPIO_PIN_13
#define LED_GPIO_CLOCK         RCU_GPIOC

/* Temporización del guion de autenticación. */
#define STEP_PERIOD_MS         850U
#define SEQUENCE_PAUSE_MS      1700U
#define SCRIPT_STEP_COUNT      5U

/* Patrones visuales del LED. */
#define SHORT_FLASH_MS         120U
#define LONG_FLASH_MS          650U

typedef enum {
    INDICATOR_IDLE = 0,
    INDICATOR_ON,
    INDICATOR_OFF
} indicator_state_t;

/*
 * Estructuras principales del ejercicio.
 *
 * Se dejan como variables globales para poder inspeccionarlas fácilmente
 * desde la ventana Watch del depurador.
 */
secure_element_t g_secure_element;
auth_verifier_t g_auth_verifier;

/* Datos intercambiados durante la autenticación. */
uint8_t g_challenge[SECURE_ELEMENT_CHALLENGE_SIZE];
uint8_t g_response[SECURE_ELEMENT_RESPONSE_SIZE];

/* Copias utilizadas para simular un ataque de repetición. */
uint8_t g_saved_challenge[SECURE_ELEMENT_CHALLENGE_SIZE];
uint8_t g_saved_response[SECURE_ELEMENT_RESPONSE_SIZE];

/* Variables observables desde el depurador. */
volatile auth_result_t g_last_auth_result =
    AUTH_RESULT_INVALID_ARGUMENT;

volatile uint32_t g_authentication_accepted = 0U;
volatile uint32_t g_authentication_rejected = 0U;

volatile uint32_t g_expected_mac_failures = 0U;
volatile uint32_t g_expected_replays = 0U;

volatile uint32_t g_script_step = 0U;
volatile uint32_t g_sequence_cycles = 0U;
volatile uint32_t g_background_iterations = 0U;

volatile uint8_t g_led_is_on = 0U;

/* Variables internas de temporización. */
static uint32_t next_test_ms = 0U;
static uint32_t indicator_deadline_ms = 0U;

static uint32_t indicator_pulses_remaining = 0U;
static uint32_t indicator_on_ms = 0U;
static uint32_t indicator_off_ms = 0U;

static indicator_state_t indicator_state = INDICATOR_IDLE;

/*
 * Comprueba si se alcanzó un instante determinado.
 *
 * La resta con signo permite que la comparación siga funcionando cuando
 * el contador de milisegundos se desborda.
 */
static uint8_t time_reached(
    uint32_t now,
    uint32_t deadline
)
{
    return ((int32_t)(now - deadline) >= 0) ? 1U : 0U;
}

/*
 * Controla el LED de PC13.
 *
 * En esta placa el LED es activo en nivel bajo:
 *   0 lógico -> LED encendido
 *   1 lógico -> LED apagado
 */
static void led_set(uint8_t turn_on)
{
    if (turn_on != 0U) {
        gpio_bit_reset(LED_GPIO_PORT, LED_GPIO_PIN);
        g_led_is_on = 1U;
    } else {
        gpio_bit_set(LED_GPIO_PORT, LED_GPIO_PIN);
        g_led_is_on = 0U;
    }
}

/* Configura PC13 como salida digital. */
static void led_init(void)
{
    rcu_periph_clock_enable(LED_GPIO_CLOCK);

    gpio_mode_set(
        LED_GPIO_PORT,
        GPIO_MODE_OUTPUT,
        GPIO_PUPD_NONE,
        LED_GPIO_PIN
    );

    gpio_output_options_set(
        LED_GPIO_PORT,
        GPIO_OTYPE_PP,
        GPIO_OSPEED_10MHZ,
        LED_GPIO_PIN
    );

    led_set(0U);
}

/*
 * Inicia una indicación no bloqueante mediante el LED.
 *
 * Una autenticación aceptada produce dos destellos cortos.
 * Una autenticación rechazada produce un destello largo.
 */
static void indicator_start(
    uint32_t now,
    uint32_t pulses,
    uint32_t on_ms,
    uint32_t off_ms
)
{
    indicator_pulses_remaining = pulses;
    indicator_on_ms = on_ms;
    indicator_off_ms = off_ms;

    indicator_state = INDICATOR_ON;

    led_set(1U);

    indicator_deadline_ms = now + indicator_on_ms;
}

/*
 * Actualiza la máquina de estados encargada del LED.
 *
 * Esta función no utiliza esperas activas. El procesador puede continuar
 * ejecutando el resto del programa mientras transcurre el tiempo.
 */
static void indicator_update(uint32_t now)
{
    if (indicator_state == INDICATOR_IDLE) {
        return;
    }

    if (time_reached(now, indicator_deadline_ms) == 0U) {
        return;
    }

    if (indicator_state == INDICATOR_ON) {
        led_set(0U);

        indicator_pulses_remaining--;

        if (indicator_pulses_remaining == 0U) {
            indicator_state = INDICATOR_IDLE;
        } else {
            indicator_state = INDICATOR_OFF;
            indicator_deadline_ms = now + indicator_off_ms;
        }
    } else {
        led_set(1U);

        indicator_state = INDICATOR_ON;
        indicator_deadline_ms = now + indicator_on_ms;
    }
}

/*
 * Construye un challenge determinista de 32 bytes.
 *
 * En un sistema real el challenge debe provenir de un generador
 * criptográficamente seguro y no debe repetirse.
 */
static void make_challenge(
    uint8_t *challenge,
    uint8_t seed
)
{
    uint32_t index;

    for (
        index = 0U;
        index < SECURE_ELEMENT_CHALLENGE_SIZE;
        index++
    ) {
        challenge[index] =
            (uint8_t)(seed + (uint8_t)(index * 13U));
    }
}

/*
 * Ejecuta una de las cinco pruebas de autenticación.
 *
 * Paso 0: challenge nuevo y respuesta válida.
 * Paso 1: challenge alterado con una respuesta anterior.
 * Paso 2: respuesta alterada en tránsito.
 * Paso 3: segundo challenge válido.
 * Paso 4: repetición de un intercambio válido anterior.
 */
static auth_result_t run_authentication_step(uint32_t step)
{
    switch (step) {
    case 0U:
        /*
         * Prueba válida.
         *
         * El elemento seguro calcula la respuesta correcta para
         * un challenge nuevo.
         */
        make_challenge(g_challenge, 0x21U);

        secure_element_compute_response(
            &g_secure_element,
            g_challenge,
            g_response
        );

        return auth_verifier_verify(
            &g_auth_verifier,
            g_challenge,
            g_response
        );

    case 1U:
        /*
         * Ataque por alteración del challenge.
         *
         * Se modifica un bit del challenge, pero se conserva la
         * respuesta calculada para el challenge original.
         */
        g_challenge[3] ^= 0x01U;

        return auth_verifier_verify(
            &g_auth_verifier,
            g_challenge,
            g_response
        );

    case 2U:
        /*
         * Ataque por alteración de la respuesta.
         *
         * La respuesta se calcula correctamente, pero después se
         * modifica uno de sus bits antes de verificarla.
         */
        make_challenge(g_challenge, 0x62U);

        secure_element_compute_response(
            &g_secure_element,
            g_challenge,
            g_response
        );

        g_response[12] ^= 0x80U;

        return auth_verifier_verify(
            &g_auth_verifier,
            g_challenge,
            g_response
        );

    case 3U:
        /*
         * Segunda autenticación válida.
         *
         * El challenge y la respuesta se guardan para reproducirlos
         * posteriormente durante el ataque de repetición.
         */
        make_challenge(g_challenge, 0xA4U);

        secure_element_compute_response(
            &g_secure_element,
            g_challenge,
            g_response
        );

        memcpy(
            g_saved_challenge,
            g_challenge,
            sizeof(g_saved_challenge)
        );

        memcpy(
            g_saved_response,
            g_response,
            sizeof(g_saved_response)
        );

        return auth_verifier_verify(
            &g_auth_verifier,
            g_challenge,
            g_response
        );

    default:
        /*
         * Ataque replay.
         *
         * El challenge y la respuesta son criptográficamente válidos,
         * pero ya fueron utilizados anteriormente.
         */
        memcpy(
            g_challenge,
            g_saved_challenge,
            sizeof(g_challenge)
        );

        memcpy(
            g_response,
            g_saved_response,
            sizeof(g_response)
        );

        return auth_verifier_verify(
            &g_auth_verifier,
            g_challenge,
            g_response
        );
    }
}

/*
 * Ejecuta periódicamente el guion de pruebas.
 */
static void test_script_update(uint32_t now)
{
    auth_result_t result;

    if (time_reached(now, next_test_ms) == 0U) {
        return;
    }

    result = run_authentication_step(g_script_step);
    g_last_auth_result = result;

    if (result == AUTH_RESULT_ACCEPTED) {
        g_authentication_accepted++;

        /*
         * Dos destellos cortos indican autenticación aceptada.
         */
        indicator_start(
            now,
            2U,
            SHORT_FLASH_MS,
            SHORT_FLASH_MS
        );
    } else {
        g_authentication_rejected++;

        if (result == AUTH_RESULT_REJECTED_MAC) {
            g_expected_mac_failures++;
        } else if (result == AUTH_RESULT_REJECTED_REPLAY) {
            g_expected_replays++;
        }

        /*
         * Un destello largo indica autenticación rechazada.
         */
        indicator_start(
            now,
            1U,
            LONG_FLASH_MS,
            SHORT_FLASH_MS
        );
    }

    g_script_step++;

    if (g_script_step >= SCRIPT_STEP_COUNT) {
        g_script_step = 0U;

        /*
         * Breakpoint principal:
         * detener aquí para revisar los resultados de las cinco pruebas.
         */
        g_sequence_cycles++;

        next_test_ms = now + SEQUENCE_PAUSE_MS;
    } else {
        next_test_ms = now + STEP_PERIOD_MS;
    }
}

int main(void)
{
    uint32_t now;

    led_init();
    systimer_init_1ms();

    secure_element_init(&g_secure_element);
    auth_verifier_init(&g_auth_verifier);

    /*
     * Primera prueba medio segundo después del arranque.
     */
    next_test_ms = systimer_millis() + 500U;

    while (1) {
        now = systimer_millis();

        test_script_update(now);
        indicator_update(now);

        /*
         * Demuestra que el procesador continúa ejecutando trabajo
         * mientras espera los eventos temporizados.
         */
        g_background_iterations++;
    }
}