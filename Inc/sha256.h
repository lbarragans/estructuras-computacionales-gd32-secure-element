#ifndef SHA256_H
#define SHA256_H
#include <stddef.h>
#include <stdint.h>
#define SHA256_DIGEST_SIZE 32U
void sha256(const uint8_t *data, size_t length, uint8_t digest[SHA256_DIGEST_SIZE]);
void hmac_sha256(const uint8_t *key, size_t key_length,
                 const uint8_t *message, size_t message_length,
                 uint8_t digest[SHA256_DIGEST_SIZE]);
#endif
