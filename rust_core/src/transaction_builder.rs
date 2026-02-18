/// Builds protocol-specific payloads for ReddID transactions.
///
/// The API in this module is intentionally small and explicit because it will be called through
/// FFI boundaries where debugging is harder and invalid inputs are more likely.

/// Maximum standard OP_RETURN payload size in bytes.
///
/// Why this exists:
/// * Most nodes/mempools enforce an 80-byte standard relay limit for OP_RETURN data.
/// * Failing fast in the Rust core gives a clearer error than letting transaction broadcast fail
///   later with a generic policy rejection.
const STANDARD_OP_RETURN_MAX_BYTES: usize = 80;

/// ReddID protocol marker bytes.
///
/// Layout rationale:
/// * `RDD` makes it easy for parsers to quickly identify payloads intended for the ReddID flow.
/// * `0x01` is a version byte so the format can evolve while preserving backward compatibility.
const REDDID_PREFIX: [u8; 4] = [b'R', b'D', b'D', 0x01];

/// Separator between command and identifier fields.
///
/// Why `0x00`:
/// * It is a simple sentinel byte that cannot be confused with ASCII letters in typical command
///   names or identifiers.
/// * It keeps parsing deterministic without requiring length prefixes.
const FIELD_SEPARATOR: u8 = 0x00;

/// Builds a hex-encoded ReddID OP_RETURN payload.
///
/// Binary layout:
/// 1. Prefix: `RDD` + version byte (`0x01`)
/// 2. Command bytes (UTF-8)
/// 3. Separator byte (`0x00`)
/// 4. Identifier bytes (UTF-8)
///
/// Returns a lowercase hexadecimal string so callers can directly inject this into transaction
/// building workflows that expect hex-encoded script data.
pub fn build_opreturn_payload(command: String, identifier: String) -> Result<String, String> {
    // Normalize only around whitespace boundaries.
    // We deliberately do NOT lowercase or otherwise mutate semantic content because command and
    // identifier formats may be version-dependent and caller-controlled.
    let command = command.trim();
    let identifier = identifier.trim();

    // Explicit input validation to produce deterministic, user-facing errors.
    if command.is_empty() {
        return Err("command cannot be empty".to_string());
    }

    if identifier.is_empty() {
        return Err("identifier cannot be empty".to_string());
    }

    // The parser uses a zero-byte separator, so disallow embedded separators in either field to
    // avoid ambiguous decoding.
    if command.as_bytes().contains(&FIELD_SEPARATOR) {
        return Err("command cannot contain null byte (0x00)".to_string());
    }

    if identifier.as_bytes().contains(&FIELD_SEPARATOR) {
        return Err("identifier cannot contain null byte (0x00)".to_string());
    }

    // Pre-calculate size before allocation so we can fail early with a useful error.
    let total_len = REDDID_PREFIX.len() + command.len() + 1 + identifier.len();
    if total_len > STANDARD_OP_RETURN_MAX_BYTES {
        return Err(format!(
            "payload too large: {total_len} bytes (max {STANDARD_OP_RETURN_MAX_BYTES})"
        ));
    }

    // Pre-allocate exact capacity to avoid repeated reallocation and to make intent obvious.
    let mut payload = Vec::with_capacity(total_len);

    // Prefix is always first so parsers can cheaply route payloads by protocol/version.
    payload.extend_from_slice(&REDDID_PREFIX);

    // Append command field bytes as-is (UTF-8 byte representation).
    payload.extend_from_slice(command.as_bytes());

    // Append explicit delimiter between fields.
    payload.push(FIELD_SEPARATOR);

    // Append identifier bytes.
    payload.extend_from_slice(identifier.as_bytes());

    // `hex::encode` returns lowercase by default, which matches the requirement.
    Ok(hex::encode(payload))
}
