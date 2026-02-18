use std::str::FromStr;

use bitcoin::absolute::LockTime;
use bitcoin::address::NetworkUnchecked;
use bitcoin::consensus::encode::serialize_hex;
use bitcoin::hashes::{hash160, Hash};
use bitcoin::script::{Builder, PushBytesBuf};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{
    secp256k1::{Message, PublicKey, Secp256k1, SecretKey},
    Address, Amount, Network, OutPoint, PublicKey as BitcoinPublicKey, ScriptBuf, Sequence,
    Transaction, TxIn, TxOut, Txid, Witness,
};
use serde::Deserialize;

/// Reddcoin's Base58 P2PKH version byte (`R...` legacy addresses).
///
/// Bitcoin mainnet uses `0x00` for P2PKH, while Reddcoin uses `0x3D`.
/// We keep this explicit because the bitcoin crate models Bitcoin-family networks,
/// so we need to consciously document and handle this divergence.
pub const REDDCOIN_VERSION_BYTE: u8 = 0x3D;

#[derive(Debug, Clone, Deserialize)]
pub struct UtxoInput {
    pub txid: String,
    pub vout: u32,
    pub amount: u64,
}

/// Signs an OP_RETURN transaction for ReddID-style payload anchoring.
///
/// This implementation follows the same cryptographic shape as Bitcoin legacy P2PKH signing:
/// 1. Build an unsigned transaction with N inputs and two outputs.
/// 2. Compute a SIGHASH digest per input being signed.
/// 3. ECDSA-sign that digest with secp256k1.
/// 4. Build scriptSig containing `<DER signature + sighash flag> <compressed pubkey>`.
/// 5. Serialize transaction bytes as lowercase hex.
///
/// Reddcoin nuance:
/// * Script system and ECDSA primitives are Bitcoin-family compatible for this flow.
/// * Address version bytes differ (`0x3D` for P2PKH), so we parse then intentionally bypass
///   strict bitcoin-network checks when building the change output script.
pub fn sign_opreturn_transaction(
    private_key_hex: String,
    utxos: Vec<UtxoInput>,
    op_return_payload: String,
    change_address: String,
    network_fee: u64,
) -> Result<String, String> {
    if private_key_hex.len() != 64 {
        return Err("private_key_hex must be exactly 64 hex characters".to_string());
    }

    if utxos.is_empty() {
        return Err("at least one UTXO input is required".to_string());
    }

    let total_input_amount = utxos.iter().try_fold(0u64, |acc, utxo| {
        acc.checked_add(utxo.amount)
            .ok_or_else(|| "total input amount overflowed u64".to_string())
    })?;

    if network_fee > total_input_amount {
        return Err("network_fee cannot exceed total input amount".to_string());
    }

    let payload_bytes = hex::decode(op_return_payload)
        .map_err(|e| format!("op_return_payload must be valid hex: {e}"))?;

    // `new_op_return` uses a push-data payload and requires the payload to be encoded as
    // minimally-pushed bytes. `PushBytesBuf` enforces script push constraints.
    let op_return_push = PushBytesBuf::try_from(payload_bytes)
        .map_err(|e| format!("OP_RETURN payload exceeds script push limits: {e}"))?;

    let change_amount = total_input_amount - network_fee;

    // -------------------------------------------------------------------------------------
    // Step 1) Parse private key material and derive the matching compressed public key.
    // -------------------------------------------------------------------------------------
    let private_key_raw =
        hex::decode(private_key_hex).map_err(|e| format!("private_key_hex decode failed: {e}"))?;
    let secret_key = SecretKey::from_slice(&private_key_raw)
        .map_err(|e| format!("invalid secp256k1 private key: {e}"))?;

    let secp = Secp256k1::new();
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);
    let bitcoin_pubkey = BitcoinPublicKey::new(public_key);

    // -------------------------------------------------------------------------------------
    // Step 2) Build tx inputs (from provided UTXOs) and outputs (OP_RETURN + change).
    // -------------------------------------------------------------------------------------
    let mut inputs = Vec::with_capacity(utxos.len());
    for (index, utxo) in utxos.iter().enumerate() {
        if utxo.txid.len() != 64 {
            return Err(format!(
                "utxos[{index}].txid must be exactly 64 hex characters"
            ));
        }

        let txid =
            Txid::from_str(&utxo.txid).map_err(|e| format!("invalid utxos[{index}].txid: {e}"))?;
        let outpoint = OutPoint {
            txid,
            vout: utxo.vout,
        };

        inputs.push(TxIn {
            previous_output: outpoint,
            script_sig: ScriptBuf::new(),
            sequence: Sequence::MAX,
            witness: Witness::new(),
        });
    }

    let op_return_output = TxOut {
        value: Amount::from_sat(0),
        script_pubkey: ScriptBuf::new_op_return(op_return_push),
    };

    // We intentionally use Address::from_str first, then bypass strict network checking.
    // This is needed because the bitcoin crate validates against Bitcoin network sets,
    // while Reddcoin has a distinct legacy version byte (`0x3D`).
    let parsed_address: Address<NetworkUnchecked> = Address::from_str(change_address.trim())
        .map_err(|e| format!("invalid change_address: {e}"))?;

    // Best-effort explicit check path (expected to fail for non-Bitcoin network encodings).
    // We ignore the result and proceed with an unchecked address because script semantics
    // are what matter for output construction, not Bitcoin-network labeling.
    let _ = parsed_address.clone().require_network(Network::Bitcoin);

    let change_script = parsed_address.assume_checked().script_pubkey();
    let change_output = TxOut {
        value: Amount::from_sat(change_amount),
        script_pubkey: change_script,
    };

    let mut tx = Transaction {
        version: bitcoin::transaction::Version(2),
        lock_time: LockTime::ZERO,
        input: inputs,
        output: vec![op_return_output, change_output],
    };

    // -------------------------------------------------------------------------------------
    // Step 3) Construct the *prevout script* for signature hashing.
    // -------------------------------------------------------------------------------------
    // For legacy P2PKH signing, the digest for input N includes the scriptPubKey of the UTXO
    // being spent (with scriptSig replaced by that script for the signing preimage).
    //
    // In this API we are given only the private key, so we assume the funding output is a
    // standard P2PKH locked to this key's HASH160.
    let pubkey_hash = hash160::Hash::hash(&bitcoin_pubkey.inner.serialize());
    let p2pkh_script = Builder::new()
        .push_opcode(bitcoin::opcodes::all::OP_DUP)
        .push_opcode(bitcoin::opcodes::all::OP_HASH160)
        .push_slice(pubkey_hash.as_byte_array())
        .push_opcode(bitcoin::opcodes::all::OP_EQUALVERIFY)
        .push_opcode(bitcoin::opcodes::all::OP_CHECKSIG)
        .into_script();

    // -------------------------------------------------------------------------------------
    // Step 4) SIGHASH computation and ECDSA signature generation.
    // -------------------------------------------------------------------------------------
    // Why this matters:
    // * The signature is not over "the transaction bytes" directly.
    // * Instead, a deterministic signing preimage is built per input, including selected
    //   transaction fields according to the sighash flag (SIGHASH_ALL here).
    // * That preimage is double-SHA256 hashed into a 32-byte message digest.
    // * secp256k1 signs that digest, yielding an ECDSA signature.
    //
    // Reddcoin vs Bitcoin note:
    // * For this legacy P2PKH path, the signing model mirrors Bitcoin's legacy algorithm.
    // * Network version-byte differences affect addresses/UI encoding, but not the ECDSA math.
    for index in 0..tx.input.len() {
        let sighash = {
            let mut sighash_cache = SighashCache::new(&mut tx);
            sighash_cache
                .legacy_signature_hash(index, &p2pkh_script, EcdsaSighashType::All.to_u32())
                .map_err(|e| format!("failed to construct sighash for input {index}: {e}"))?
        };

        let message = Message::from_digest(*sighash.as_byte_array());
        let ecdsa_signature = secp.sign_ecdsa(&message, &secret_key);

        // Bitcoin-style scriptSig needs DER signature + one sighash-type byte.
        let bitcoin_signature = bitcoin::ecdsa::Signature {
            signature: ecdsa_signature,
            sighash_type: EcdsaSighashType::All,
        };
        let signature_with_hashtype = bitcoin_signature.to_vec();

        let sig_push = PushBytesBuf::try_from(signature_with_hashtype)
            .map_err(|e| format!("signature encoding failed push-bytes checks: {e}"))?;
        let pubkey_push = PushBytesBuf::try_from(bitcoin_pubkey.to_bytes())
            .map_err(|e| format!("public key encoding failed push-bytes checks: {e}"))?;

        let script_sig = Builder::new()
            .push_slice(sig_push)
            .push_slice(pubkey_push)
            .into_script();

        tx.input[index].script_sig = script_sig;
    }

    Ok(serialize_hex(&tx))
}
