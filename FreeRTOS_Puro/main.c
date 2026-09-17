#include <stdint.h>

#include "app_cfg.h"
#include "gd32vw55x_platform.h"
#include "wrapper_os.h"
#include <string.h>

#include "FreeRTOS.h"
#include "queue.h"
#include "task.h"
#include "gd32vw55x.h"
#include "sha256.h"

#define LED_GPIO_PORT GPIOC
#define LED_GPIO_PIN GPIO_PIN_13
#define LED_GPIO_CLOCK RCU_GPIOC
#define ACCEPTED 0U
#define REJECTED_MAC 1U
#define REJECTED_REPLAY 2U

static const uint8_t device_key[32] = {
    0x31U,0xA7U,0x09U,0xD2U,0x8EU,0x44U,0xF1U,0x6CU,
    0x90U,0x13U,0x5BU,0xC8U,0x22U,0xE7U,0x6AU,0x0DU,
    0xB4U,0x58U,0xCFU,0x72U,0x19U,0xA0U,0x35U,0xEBU,
    0x86U,0x2DU,0xF9U,0x41U,0x67U,0xBCU,0x04U,0xD5U
};

static QueueHandle_t result_queue;
static uint8_t challenge[32];
static uint8_t response[32];
static uint8_t saved_challenge[32];
static uint8_t saved_response[32];
static uint8_t last_accepted_challenge[32];
static uint8_t has_last_challenge;

volatile uint32_t g_commands_executed = 0U;
volatile uint32_t g_verification_attempts = 0U;
volatile uint32_t g_authentication_accepted = 0U;
volatile uint32_t g_authentication_rejected = 0U;
volatile uint32_t g_expected_mac_failures = 0U;
volatile uint32_t g_expected_replays = 0U;
volatile uint32_t g_script_step = 0U;
volatile uint32_t g_sequence_cycles = 0U;
volatile uint8_t g_last_auth_result = REJECTED_MAC;

static uint8_t constant_time_equal(const uint8_t *a, const uint8_t *b)
{
    uint8_t difference = 0U;
    uint32_t index;
    for (index = 0U; index < 32U; index++) {
        difference |= (uint8_t)(a[index] ^ b[index]);
    }
    return (difference == 0U) ? 1U : 0U;
}

static void make_challenge(uint8_t seed)
{
    uint32_t index;
    for (index = 0U; index < 32U; index++) {
        challenge[index] = (uint8_t)(seed + (uint8_t)(index * 13U));
    }
}

static void compute_response(void)
{
    hmac_sha256(device_key, sizeof(device_key), challenge,
                sizeof(challenge), response);
    g_commands_executed++;
}

static uint8_t verify_response(void)
{
    uint8_t expected[32];
    g_verification_attempts++;

    if ((has_last_challenge != 0U) &&
        (constant_time_equal(challenge, last_accepted_challenge) != 0U)) {
        return REJECTED_REPLAY;
    }

    hmac_sha256(device_key, sizeof(device_key), challenge,
                sizeof(challenge), expected);
    if (constant_time_equal(expected, response) == 0U) {
        return REJECTED_MAC;
    }

    memcpy(last_accepted_challenge, challenge, sizeof(challenge));
    has_last_challenge = 1U;
    return ACCEPTED;
}

static uint8_t run_step(uint32_t step)
{
    if (step == 0U) {
        make_challenge(0x21U);
        compute_response();
    } else if (step == 1U) {
        challenge[3] ^= 0x01U;
    } else if (step == 2U) {
        make_challenge(0x62U);
        compute_response();
        response[12] ^= 0x80U;
    } else if (step == 3U) {
        make_challenge(0xA4U);
        compute_response();
        memcpy(saved_challenge, challenge, sizeof(challenge));
        memcpy(saved_response, response, sizeof(response));
    } else {
        memcpy(challenge, saved_challenge, sizeof(challenge));
        memcpy(response, saved_response, sizeof(response));
    }
    return verify_response();
}

static void authentication_task(void *argument)
{
    (void)argument;
    vTaskDelay(pdMS_TO_TICKS(500U));
    for (;;) {
        uint8_t result = run_step(g_script_step);
        g_last_auth_result = result;
        if (result == ACCEPTED) {
            g_authentication_accepted++;
        } else {
            g_authentication_rejected++;
            if (result == REJECTED_MAC) g_expected_mac_failures++;
            if (result == REJECTED_REPLAY) g_expected_replays++;
        }
        (void)xQueueSend(result_queue, &result, portMAX_DELAY);
        g_script_step++;
        if (g_script_step >= 5U) {
            g_script_step = 0U;
            g_sequence_cycles++;
            vTaskDelay(pdMS_TO_TICKS(1700U));
        } else {
            vTaskDelay(pdMS_TO_TICKS(850U));
        }
    }
}

static void led_set(uint8_t on)
{
    if (on != 0U) gpio_bit_set(LED_GPIO_PORT, LED_GPIO_PIN);
    else gpio_bit_reset(LED_GPIO_PORT, LED_GPIO_PIN);
}

static void indicator_task(void *argument)
{
    (void)argument;
    for (;;) {
        uint8_t result;
        uint32_t pulse;
        (void)xQueueReceive(result_queue, &result, portMAX_DELAY);
        if (result == ACCEPTED) {
            for (pulse = 0U; pulse < 2U; pulse++) {
                led_set(1U); vTaskDelay(pdMS_TO_TICKS(120U));
                led_set(0U); vTaskDelay(pdMS_TO_TICKS(120U));
            }
        } else {
            led_set(1U); vTaskDelay(pdMS_TO_TICKS(650U));
            led_set(0U); vTaskDelay(pdMS_TO_TICKS(120U));
        }
    }
}

int main(void)
{
    BaseType_t authentication_ok;
    BaseType_t indicator_ok;

    sys_os_init();
    platform_init();
    rcu_periph_clock_enable(LED_GPIO_CLOCK);
    gpio_mode_set(LED_GPIO_PORT, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, LED_GPIO_PIN);
    gpio_output_options_set(LED_GPIO_PORT, GPIO_OTYPE_PP,
                            GPIO_OSPEED_10MHZ, LED_GPIO_PIN);
    led_set(0U);

    memset(last_accepted_challenge, 0, sizeof(last_accepted_challenge));
    has_last_challenge = 0U;
    result_queue = xQueueCreate(8U, sizeof(uint8_t));
    if (result_queue == NULL) for (;;) { }

    authentication_ok = xTaskCreate(authentication_task, "Auth",
                                    configMINIMAL_STACK_SIZE * 3U, NULL,
                                    tskIDLE_PRIORITY + 2U, NULL);
    indicator_ok = xTaskCreate(indicator_task, "LED",
                               configMINIMAL_STACK_SIZE, NULL,
                               tskIDLE_PRIORITY + 1U, NULL);
    if ((authentication_ok != pdPASS) || (indicator_ok != pdPASS))
        for (;;) { }
    sys_os_start();
    for (;;) { }
}
