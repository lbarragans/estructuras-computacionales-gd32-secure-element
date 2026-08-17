#include "secure_element_sim.h"
#include <stddef.h>
#include <string.h>
#include "sha256.h"

/* Educational only: unlike a real secure element, this key is in firmware. */
static const uint8_t device_key[32] = {
    0x31U,0xA7U,0x09U,0xD2U,0x8EU,0x44U,0xF1U,0x6CU,
    0x90U,0x13U,0x5BU,0xC8U,0x22U,0xE7U,0x6AU,0x0DU,
    0xB4U,0x58U,0xCFU,0x72U,0x19U,0xA0U,0x35U,0xEBU,
    0x86U,0x2DU,0xF9U,0x41U,0x67U,0xBCU,0x04U,0xD5U
};
static const uint8_t verifier_key[32] = {
    0x31U,0xA7U,0x09U,0xD2U,0x8EU,0x44U,0xF1U,0x6CU,
    0x90U,0x13U,0x5BU,0xC8U,0x22U,0xE7U,0x6AU,0x0DU,
    0xB4U,0x58U,0xCFU,0x72U,0x19U,0xA0U,0x35U,0xEBU,
    0x86U,0x2DU,0xF9U,0x41U,0x67U,0xBCU,0x04U,0xD5U
};

static uint8_t constant_time_equal(const uint8_t *a, const uint8_t *b,
                                   uint32_t length)
{
    uint8_t difference = 0U;
    uint32_t i;
    for (i = 0U; i < length; ++i) difference |= (uint8_t)(a[i] ^ b[i]);
    return (difference == 0U) ? 1U : 0U;
}

void secure_element_init(secure_element_t *device)
{
    static const uint8_t serial[SECURE_ELEMENT_SERIAL_SIZE] =
        {0x01U,0x23U,0x45U,0x67U,0x89U,0xABU,0xCDU,0xEFU,0x11U};
    memset(device, 0, sizeof(*device));
    memcpy(device->serial, serial, sizeof(serial));
}

void secure_element_compute_response(secure_element_t *device,
    const uint8_t challenge[SECURE_ELEMENT_CHALLENGE_SIZE],
    uint8_t response[SECURE_ELEMENT_RESPONSE_SIZE])
{
    device->commands_executed++;
    hmac_sha256(device_key, sizeof(device_key), challenge,
                SECURE_ELEMENT_CHALLENGE_SIZE, response);
    device->responses_generated++;
}

void auth_verifier_init(auth_verifier_t *verifier)
{
    memset(verifier, 0, sizeof(*verifier));
}

auth_result_t auth_verifier_verify(auth_verifier_t *verifier,
    const uint8_t challenge[SECURE_ELEMENT_CHALLENGE_SIZE],
    const uint8_t response[SECURE_ELEMENT_RESPONSE_SIZE])
{
    uint8_t expected[SECURE_ELEMENT_RESPONSE_SIZE];
    if ((verifier == NULL) || (challenge == NULL) || (response == NULL))
        return AUTH_RESULT_INVALID_ARGUMENT;
    verifier->verification_attempts++;
    if ((verifier->has_last_challenge != 0U) &&
        (constant_time_equal(challenge, verifier->last_accepted_challenge,
                             SECURE_ELEMENT_CHALLENGE_SIZE) != 0U)) {
        verifier->rejected_replay++;
        return AUTH_RESULT_REJECTED_REPLAY;
    }
    hmac_sha256(verifier_key, sizeof(verifier_key), challenge,
                SECURE_ELEMENT_CHALLENGE_SIZE, expected);
    if (constant_time_equal(expected, response,
                            SECURE_ELEMENT_RESPONSE_SIZE) == 0U) {
        verifier->rejected_mac++;
        return AUTH_RESULT_REJECTED_MAC;
    }
    memcpy(verifier->last_accepted_challenge, challenge,
           SECURE_ELEMENT_CHALLENGE_SIZE);
    verifier->has_last_challenge = 1U;
    verifier->accepted++;
    return AUTH_RESULT_ACCEPTED;
}
