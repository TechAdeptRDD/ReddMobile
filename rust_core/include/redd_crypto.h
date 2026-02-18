#ifndef REDD_CRYPTO_H
#define REDD_CRYPTO_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Generates a ReddID OP_RETURN payload encoded as a lowercase hexadecimal C string.
 *
 * This function bridges into the Rust transaction builder and constructs payloads with the
 * following binary shape before hex encoding:
 *   - Protocol prefix: "RDD" + version byte 0x01
 *   - Command bytes (UTF-8)
 *   - Separator byte 0x00
 *   - Identifier bytes (UTF-8)
 *
 * Return format:
 *   - On success: "OK:<hex_payload>"
 *   - On error:   "ERR:<error_message>"
 *
 * @param command
 *   Pointer to a NUL-terminated UTF-8 C string describing the ReddID command
 *   (for example: "nsbid", "nsauc"). Must not be NULL.
 *
 * @param identifier
 *   Pointer to a NUL-terminated UTF-8 C string holding the identifier value
 *   (for example: "techadept.redd"). Must not be NULL.
 *
 * @return
 *   Heap-allocated C string owned by Rust. The caller MUST release this memory by calling
 *   `vault_string_free` after use. Failing to free the pointer will leak memory.
 */
char *generate_reddid_payload_ffi(const char *command, const char *identifier);

/**
 * Frees C strings allocated and returned by Rust FFI functions in this library.
 */
void vault_string_free(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* REDD_CRYPTO_H */
