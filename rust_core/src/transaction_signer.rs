use std::str::FromStr;

use bitcoin::absolute::LockTime;
use bitcoin::consensus::encode::serialize_hex;
use bitcoin::hashes::{hash160, Hash};
use bitcoin::script::{Builder, PushBytesBuf};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{
    secp256k1::{Message, PublicKey, Secp256k1, SecretKey},
    Address, Amount, OutPoint, PublicKey as BitcoinPublicKey, ScriptBuf, Sequence, Transaction,
    TxIn, TxOut, Txid, Witness,
};
use serde::Deserialize;

/// Reddcoin's Base58 P2PKH version byte (`R...` legacy addresses).
///
/// Bitcoin mainnet uses `0x00` for P2PKH, while Reddcoin uses `0x3D`.
/// We keep this explicit because the bitcoin crate models Bitcoin-family networks,
/// so we need to consciously document and handle this divergence.
pub const REDDCOIN_VERSION_BYTE: u8 = 0x3D;
const LEGACY_BASE_TX_SIZE: u64 = 10;
const LEGACY_P2PKH_INPUT_SIZE: u64 = 148;
const LEGACY_OUTPUT_SIZE: u64 = 34;
const LEGACY_P2PKH_DUST_LIMIT: u64 = 546;

fn estimate_legacy_tx_fee(inputs: usize, outputs: usize, fee_per_kb: u64) -> Result<u64, String> {
    let tx_size = LEGACY_BASE_TX_SIZE
        .checked_add((inputs as u64).saturating_mul(LEGACY_P2PKH_INPUT_SIZE))
        .and_then(|v| v.checked_add((outputs as u64).saturating_mul(LEGACY_OUTPUT_SIZE)))
        .ok_or_else(|| "fee calculation overflowed tx size".to_string())?;

    let fee_numerator = tx_size
        .checked_mul(fee_per_kb)
        .and_then(|v| v.checked_add(999))
        .ok_or_else(|| "fee calculation overflowed u64".to_string())?;

    Ok(fee_numerator / 1000)
}

#[derive(Debug, Clone, Deserialize)]
pub struct Utxo {
    pub txid: String,
    pub vout: u32,
    pub amount: u64,
}

/// Signs an OP_RETURN transaction for ReddID-style payload anchoring.
///
/// Input UTXOs are accepted as a JSON array string and each input is signed with the same
/// private key under legacy P2PKH semantics.
pub fn sign_opreturn_transaction(
    utxos_json: String,
    private_key_hex: String,
    op_return_data: String,
    change_address: String,
    fee_per_kb: u64,
) -> Result<String, String> {
    if private_key_hex.len() != 64 {
        return Err("private_key_hex must be exactly 64 hex characters".to_string());
    }

    let utxos: Vec<Utxo> = serde_json::from_str(&utxos_json)
        .map_err(|e| format!("utxos_json must be a valid JSON array of UTXOs: {e}"))?;

    if utxos.is_empty() {
        return Err("at least one UTXO input is required".to_string());
    }

    let total_input_amount = utxos.iter().try_fold(0u64, |acc, utxo| {
        acc.checked_add(utxo.amount)
            .ok_or_else(|| "total input amount overflowed u64".to_string())
    })?;

    let payload_bytes = hex::decode(op_return_data)
        .map_err(|e| format!("op_return_data must be valid hex: {e}"))?;

    let op_return_push = PushBytesBuf::try_from(payload_bytes)
        .map_err(|e| format!("OP_RETURN payload exceeds script push limits: {e}"))?;

    let private_key_raw =
        hex::decode(private_key_hex).map_err(|e| format!("private_key_hex decode failed: {e}"))?;
    let secret_key = SecretKey::from_slice(&private_key_raw)
        .map_err(|e| format!("invalid secp256k1 private key: {e}"))?;

    let secp = Secp256k1::new();
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);
    let bitcoin_pubkey = BitcoinPublicKey::new(public_key);

    let mut inputs = Vec::with_capacity(utxos.len());
    for (index, utxo) in utxos.iter().enumerate() {
        if utxo.txid.len() != 64 {
            return Err(format!(
                "utxos[{index}].txid must be exactly 64 hex characters"
            ));
        }

        let txid =
            Txid::from_str(&utxo.txid).map_err(|e| format!("invalid utxos[{index}].txid: {e}"))?;

        inputs.push(TxIn {
            previous_output: OutPoint {
                txid,
                vout: utxo.vout,
            },
            script_sig: ScriptBuf::new(),
            sequence: Sequence::MAX,
            witness: Witness::new(),
        });
    }

    let op_return_output = TxOut {
        value: Amount::from_sat(0),
        script_pubkey: ScriptBuf::new_op_return(op_return_push),
    };
    let op_return_cost = op_return_output.value.to_sat();

    let address = Address::from_str(&change_address)
        .map(|addr| addr.assume_checked())
        .map_err(|e| format!("invalid change_address: {e}"))?;
    let change_script = address.script_pubkey();

    let mut tx = Transaction {
        version: bitcoin::transaction::Version(2),
        lock_time: LockTime::ZERO,
        input: inputs,
        output: vec![
            op_return_output,
            TxOut {
                value: Amount::from_sat(0),
                script_pubkey: change_script,
            },
        ],
    };

    let mut absolute_fee = estimate_legacy_tx_fee(tx.input.len(), tx.output.len(), fee_per_kb)?;

    let mut required_amount = op_return_cost
        .checked_add(absolute_fee)
        .ok_or_else(|| "required amount overflowed u64".to_string())?;

    if required_amount > total_input_amount {
        return Err(format!(
            "insufficient funds: inputs={total_input_amount}, required={required_amount} (op_return={op_return_cost}, fee={absolute_fee})"
        ));
    }

    let mut change_value = total_input_amount - required_amount;
    if change_value > 0 && change_value < LEGACY_P2PKH_DUST_LIMIT {
        absolute_fee = absolute_fee
            .checked_add(change_value)
            .ok_or_else(|| "fee calculation overflowed dust adjustment".to_string())?;
        required_amount = op_return_cost
            .checked_add(absolute_fee)
            .ok_or_else(|| "required amount overflowed dust adjustment".to_string())?;
        change_value = 0;
    }

    tx.output[1].value = Amount::from_sat(change_value);

    let pubkey_hash = hash160::Hash::hash(&bitcoin_pubkey.inner.serialize());
    let p2pkh_script = Builder::new()
        .push_opcode(bitcoin::opcodes::all::OP_DUP)
        .push_opcode(bitcoin::opcodes::all::OP_HASH160)
        .push_slice(pubkey_hash.as_byte_array())
        .push_opcode(bitcoin::opcodes::all::OP_EQUALVERIFY)
        .push_opcode(bitcoin::opcodes::all::OP_CHECKSIG)
        .into_script();

    for index in 0..tx.input.len() {
        let sighash = {
            let sighash_cache = SighashCache::new(&mut tx);
            sighash_cache
                .legacy_signature_hash(index, &p2pkh_script, EcdsaSighashType::All.to_u32())
                .map_err(|e| format!("failed to construct sighash for input {index}: {e}"))?
        };

        let message = Message::from_digest(*sighash.as_byte_array());
        let ecdsa_signature = secp.sign_ecdsa(&message, &secret_key);

        let bitcoin_signature = bitcoin::ecdsa::Signature {
            signature: ecdsa_signature,
            sighash_type: EcdsaSighashType::All,
        };
        let signature_with_hashtype = bitcoin_signature.to_vec();

        let sig_push = PushBytesBuf::try_from(signature_with_hashtype)
            .map_err(|e| format!("signature encoding failed push-bytes checks: {e}"))?;
        let pubkey_push = PushBytesBuf::try_from(bitcoin_pubkey.to_bytes())
            .map_err(|e| format!("public key encoding failed push-bytes checks: {e}"))?;

        tx.input[index].script_sig = Builder::new()
            .push_slice(sig_push)
            .push_slice(pubkey_push)
            .into_script();
    }

    Ok(serialize_hex(&tx))
}

/// Backward-compatible alias for multi-input signing callers.
pub fn sign_multi_input_transaction(
    utxos_json: String,
    private_key_hex: String,
    op_return_data: String,
    change_address: String,
    fee_per_kb: u64,
) -> Result<String, String> {
    sign_opreturn_transaction(
        utxos_json,
        private_key_hex,
        op_return_data,
        change_address,
        fee_per_kb,
    )
}

/// Signs a standard P2PKH transfer with recipient and change outputs.
pub fn sign_standard_transfer(
    utxos_json: String,
    private_key_hex: String,
    recipient_address: String,
    change_address: String,
    amount_to_send: u64,
    fee_per_kb: u64,
) -> Result<String, String> {
    if private_key_hex.len() != 64 {
        return Err("private_key_hex must be exactly 64 hex characters".to_string());
    }

    let utxos: Vec<Utxo> = serde_json::from_str(&utxos_json)
        .map_err(|e| format!("utxos_json must be a valid JSON array of UTXOs: {e}"))?;

    if utxos.is_empty() {
        return Err("at least one UTXO input is required".to_string());
    }

    let total_input_amount = utxos.iter().try_fold(0u64, |acc, utxo| {
        acc.checked_add(utxo.amount)
            .ok_or_else(|| "total input amount overflowed u64".to_string())
    })?;

    let private_key_raw =
        hex::decode(private_key_hex).map_err(|e| format!("private_key_hex decode failed: {e}"))?;
    let secret_key = SecretKey::from_slice(&private_key_raw)
        .map_err(|e| format!("invalid secp256k1 private key: {e}"))?;

    let secp = Secp256k1::new();
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);
    let bitcoin_pubkey = BitcoinPublicKey::new(public_key);

    let mut inputs = Vec::with_capacity(utxos.len());
    for (index, utxo) in utxos.iter().enumerate() {
        if utxo.txid.len() != 64 {
            return Err(format!(
                "utxos[{index}].txid must be exactly 64 hex characters"
            ));
        }

        let txid =
            Txid::from_str(&utxo.txid).map_err(|e| format!("invalid utxos[{index}].txid: {e}"))?;

        inputs.push(TxIn {
            previous_output: OutPoint {
                txid,
                vout: utxo.vout,
            },
            script_sig: ScriptBuf::new(),
            sequence: Sequence::MAX,
            witness: Witness::new(),
        });
    }

    let recipient_script = Address::from_str(&recipient_address)
        .map(|addr| addr.assume_checked())
        .map_err(|e| format!("invalid recipient_address: {e}"))?
        .script_pubkey();
    let change_script = Address::from_str(&change_address)
        .map(|addr| addr.assume_checked())
        .map_err(|e| format!("invalid change_address: {e}"))?
        .script_pubkey();

    let mut tx = Transaction {
        version: bitcoin::transaction::Version(2),
        lock_time: LockTime::ZERO,
        input: inputs,
        output: vec![
            TxOut {
                value: Amount::from_sat(amount_to_send),
                script_pubkey: recipient_script,
            },
            TxOut {
                value: Amount::from_sat(0),
                script_pubkey: change_script,
            },
        ],
    };

    let mut absolute_fee = estimate_legacy_tx_fee(tx.input.len(), tx.output.len(), fee_per_kb)?;

    let mut required_amount = amount_to_send
        .checked_add(absolute_fee)
        .ok_or_else(|| "required amount overflowed u64".to_string())?;

    if required_amount > total_input_amount {
        return Err(format!(
            "insufficient funds: inputs={total_input_amount}, required={required_amount} (send={amount_to_send}, fee={absolute_fee})"
        ));
    }

    let mut change_value = total_input_amount - required_amount;
    if change_value > 0 && change_value < LEGACY_P2PKH_DUST_LIMIT {
        absolute_fee = absolute_fee
            .checked_add(change_value)
            .ok_or_else(|| "fee calculation overflowed dust adjustment".to_string())?;
        required_amount = amount_to_send
            .checked_add(absolute_fee)
            .ok_or_else(|| "required amount overflowed dust adjustment".to_string())?;
        if required_amount > total_input_amount {
            return Err(format!(
                "insufficient funds after dust adjustment: inputs={total_input_amount}, required={required_amount}"
            ));
        }
        change_value = 0;
    }

    tx.output[1].value = Amount::from_sat(change_value);

    let pubkey_hash = hash160::Hash::hash(&bitcoin_pubkey.inner.serialize());
    let p2pkh_script = Builder::new()
        .push_opcode(bitcoin::opcodes::all::OP_DUP)
        .push_opcode(bitcoin::opcodes::all::OP_HASH160)
        .push_slice(pubkey_hash.as_byte_array())
        .push_opcode(bitcoin::opcodes::all::OP_EQUALVERIFY)
        .push_opcode(bitcoin::opcodes::all::OP_CHECKSIG)
        .into_script();

    for index in 0..tx.input.len() {
        let sighash = {
            let sighash_cache = SighashCache::new(&mut tx);
            sighash_cache
                .legacy_signature_hash(index, &p2pkh_script, EcdsaSighashType::All.to_u32())
                .map_err(|e| format!("failed to construct sighash for input {index}: {e}"))?
        };

        let message = Message::from_digest(*sighash.as_byte_array());
        let ecdsa_signature = secp.sign_ecdsa(&message, &secret_key);

        let bitcoin_signature = bitcoin::ecdsa::Signature {
            signature: ecdsa_signature,
            sighash_type: EcdsaSighashType::All,
        };
        let signature_with_hashtype = bitcoin_signature.to_vec();

        let sig_push = PushBytesBuf::try_from(signature_with_hashtype)
            .map_err(|e| format!("signature encoding failed push-bytes checks: {e}"))?;
        let pubkey_push = PushBytesBuf::try_from(bitcoin_pubkey.to_bytes())
            .map_err(|e| format!("public key encoding failed push-bytes checks: {e}"))?;

        tx.input[index].script_sig = Builder::new()
            .push_slice(sig_push)
            .push_slice(pubkey_push)
            .into_script();
    }

    Ok(serialize_hex(&tx))
}
