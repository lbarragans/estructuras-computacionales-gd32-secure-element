#ifndef SECURE_ELEMENT_SIM_H
#define SECURE_ELEMENT_SIM_H
#include <stdint.h>
#define SECURE_ELEMENT_CHALLENGE_SIZE 32U
#define SECURE_ELEMENT_RESPONSE_SIZE 32U
#define SECURE_ELEMENT_SERIAL_SIZE 9U
typedef struct {
    uint8_t serial[SECURE_ELEMENT_SERIAL_SIZE];
    uint32_t commands_executed;
    uint32_t responses_generated;
} secure_element_t;
typedef struct {
    uint8_t last_accepted_challenge[SECURE_ELEMENT_CHALLENGE_SIZE];
    uint8_t has_last_challenge;
    uint32_t verification_attempts;
    uint32_t accepted;
    uint32_t rejected_mac;
    uint32_t rejected_replay;
} auth_verifier_t;
typedef enum {
    AUTH_RESULT_ACCEPTED = 0,
    AUTH_RESULT_REJECTED_MAC,
    AUTH_RESULT_REJECTED_REPLAY,
    AUTH_RESULT_INVALID_ARGUMENT
} auth_result_t;
void secure_element_init(secure_element_t *device);
void secure_element_compute_response(secure_element_t *device,
    const uint8_t challenge[SECURE_ELEMENT_CHALLENGE_SIZE],
    uint8_t response[SECURE_ELEMENT_RESPONSE_SIZE]);
void auth_verifier_init(auth_verifier_t *verifier);
auth_result_t auth_verifier_verify(auth_verifier_t *verifier,
    const uint8_t challenge[SECURE_ELEMENT_CHALLENGE_SIZE],
    const uint8_t response[SECURE_ELEMENT_RESPONSE_SIZE]);
#endif
