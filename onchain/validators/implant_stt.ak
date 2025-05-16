use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{Datum, OutputReference, Transaction}

pub type Step {
  Mint
  Process(Int)
}

pub type ImplDatum {
  step: Step,
  operator_pkh: Credential,
  meta_hashes: List<ByteArray>,
}

pub type ImplRedeemer {
  MintR
  Update(ByteArray)
  BurnR
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

validator implant_stt(p: Params) {
  mint(red: ImplRedeemer, policy_id: PolicyId, tx: Transaction) {
    when red is {
      MintR -> {
        let forged = quantity_of(tx.mint, policy_id, p.asset)
        let has_out =
          list.any(
            tx.outputs,
            fn(o) {
              is_nft(o.value, p) && when o.datum is {
                Datum.InlineDatum(raw) -> {
                  expect d: ImplDatum = raw
                  d.step == Mint
                }
                _ -> False
              }
            },
          )
        forged == 1 && has_out
      }
      _ -> False
    }
  }

  spend(
    d_opt: Option<ImplDatum>,
    red: ImplRedeemer,
    ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = d_opt
    let Transaction { inputs, outputs, mint, extra_signatories, .. } = tx
    expect Some(inp) = list.find(inputs, fn(i) { i.output_reference == ref })
    let in_has = is_nft(inp.output.value, p)
    let out_has = list.any(outputs, fn(o) { is_nft(o.value, p) })

    when red is {
      Update(h) -> {
        let forged = quantity_of(mint, p.policy_id, p.asset)
        forged == 0 && list.any(
          outputs,
          fn(o) {
            is_nft(o.value, p) && when o.datum is {
              Datum.InlineDatum(raw2) -> {
                expect nd: ImplDatum = raw2
                let step_ok =
                  when d.step is {
                    Mint -> nd.step == Process(1)
                    Process(i) -> nd.step == Process(i + 1)
                  }
                step_ok && nd.meta_hashes == list.concat(d.meta_hashes, [h]) && nd.operator_pkh == d.operator_pkh
              }
              _ -> False
            }
          },
        ) && signed_by(d.operator_pkh, extra_signatories)
      }
      BurnR -> {
        let forged = quantity_of(mint, p.policy_id, p.asset)
        in_has && !out_has && forged == -1 && signed_by(
          d.operator_pkh,
          extra_signatories,
        )
      }
      _ -> False
    }
  }

  else(_) {
    False
  }
}
