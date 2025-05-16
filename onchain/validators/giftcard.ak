use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{OutputReference, Transaction}

// Diese Typen werden jetzt public, damit sie im Validator-Interface sichtbar sind
pub type GiftDatum {
  owner: Credential,
  value: Int,
}

pub type GiftRedeemer {
  Mint(Int)
  Redeem
  Burn
}

pub type Params {
  policy_id: PolicyId,
  asset: AssetName,
}

fn is_nft(v, p: Params) -> Bool {
  quantity_of(v, p.policy_id, p.asset) == 1
}

fn signed_by(c: Credential, sigs: List<VerificationKeyHash>) -> Bool {
  when c is {
    Credential.VerificationKey(vkh) -> list.has(sigs, vkh)
    _ -> False
  }
}

validator giftcard(p: Params) {
  mint(r: GiftRedeemer, policy_id: PolicyId, tx: Transaction) {
    when r is {
      Mint(n) ->
        quantity_of(tx.mint, policy_id, p.asset) == n && list.length(
          list.filter(tx.outputs, fn(o) { is_nft(o.value, p) }),
        ) == n
      _ -> False
    }
  }

  spend(
    d_opt: Option<GiftDatum>,
    r: GiftRedeemer,
    utxo: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = d_opt

    let inputs = tx.inputs
    let outputs = tx.outputs
    let minted = tx.mint
    let extra_signatories = tx.extra_signatories

    expect Some(inp) = list.find(inputs, fn(i) { i.output_reference == utxo })
    let in_nft = is_nft(inp.output.value, p)
    let out_nft = list.any(outputs, fn(o) { is_nft(o.value, p) })
    let burned = quantity_of(minted, p.policy_id, p.asset) == -1
    let signer = signed_by(d.owner, extra_signatories)

    when r is {
      Redeem | Burn -> and {
          in_nft,
          !out_nft,
          burned,
          signer,
        }
      _ -> False
    }
  }

  else(_ctx: ScriptContext) {
    False
  }
}
