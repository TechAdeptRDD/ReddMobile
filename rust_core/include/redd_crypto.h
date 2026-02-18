#ifndef REDD_CRYPTO_H
#define REDD_CRYPTO_H

#include <stddef.h>
#include <stdint.h>

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
 * Constructs and signs (mock architectural implementation) an OP_RETURN transaction used by the
 * ReddMobile ReddID workflow, then returns a raw transaction hex string.
 *
 * Current behavior:
 *   - Performs strict input validation.
 *   - Builds a transaction-like mock wire structure that mirrors expected signing stages.
 *   - Returns deterministic hex output for FFI integration tests.
 *
 * Planned production behavior:
 *   - Build a real UTXO transaction for the Reddcoin network.
 *   - Output 0: OP_RETURN script carrying `op_return_payload`.
 *   - Output 1: P2PKH change output with amount `(utxo_amount - network_fee)`.
 *   - Sign inputs with secp256k1 ECDSA and return serialized raw transaction hex.
 *
 * Return format:
 *   - On success: "OK:<raw_tx_hex>"
 *   - On error:   "ERR:<error_message>"
 *
 * @param private_key_hex
 *   Pointer to a NUL-terminated hex string (64 hex chars) for a 32-byte private key.
 *
 * @param utxo_txid
 *   Pointer to a NUL-terminated hex transaction ID string for the UTXO being spent.
 *
 * @param utxo_vout
 *   The zero-based output index inside the funding transaction.
 *
 * @param utxo_amount
 *   Value of the selected UTXO in satoshis/redds (base units).
 *
 * @param op_return_payload
 *   Pointer to a NUL-terminated hex payload that will be placed into OP_RETURN.
 *
 * @param change_address
 *   Pointer to a NUL-terminated wallet address string for returning change.
 *
 * @param network_fee
 *   Transaction fee in satoshis/redds to subtract from `utxo_amount`.
 *
 * @return
 *   Heap-allocated C string owned by Rust. The caller MUST release this memory by calling
 *   `vault_string_free` exactly once.
 */
char *sign_opreturn_transaction_ffi(
    const char *private_key_hex,
    const char *utxo_txid,
    uint32_t utxo_vout,
    uint64_t utxo_amount,
    const char *op_return_payload,
    const char *change_address,
    uint64_t network_fee);

/**
 * Frees C strings allocated and returned by Rust FFI functions in this library.
 */
void vault_string_free(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* REDD_CRYPTO_H */
