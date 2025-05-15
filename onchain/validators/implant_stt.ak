use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/script_context.{ScriptContext, Spending}
use cardano/transaction.{Datum, OutputReference, Transaction}

type Step {
  Mint
  Process(Int)
  Burn
}

type ImplDatum {
  step: Step,
  operator_pkh: Credential,
  meta_hashes: List<ByteArray>,
}

type ImplRedeemer {
  MintR
  Update(ByteArray)
  BurnR
}

type Params {
  policy_id: PolicyId,
  asset: AssetName,
}

fn is_impl_nft(v, p: Params) -> Bool {
  quantity_of(v, p.policy_id, p.asset) == 1
}

fn signer_matches(c: Credential, sigs: List<VerificationKeyHash>) -> Bool {
  when c is {
    Credential.VerificationKey(vkh) -> list.has(sigs, vkh)
    _ -> False
  }
}

validator implant(p: Params) {
  mint(r: ImplRedeemer, policy_id: PolicyId, ctx: ScriptContext) {
    let ScriptContext { transaction, .. } = ctx
    when r is {
      MintR -> {
        let minted = quantity_of(transaction.mint, policy_id, p.asset)
        let ok_nft = minted == 1
        let ok_out =
          list.any(
            transaction.outputs,
            fn(o) {
              is_impl_nft(o.value, p) && when o.datum is {
                Datum.InlineDatum(raw) -> {
                  expect d: ImplDatum = raw
                  d.step == Mint
                }
                _ -> False
              }
            },
          )
        ok_nft && ok_out
      }
      _ -> False
    }
  }

  spend(d_opt: Option<ImplDatum>, r: ImplRedeemer, ctx: ScriptContext) {
    expect Some(d) = d_opt
    let ScriptContext { transaction, info, .. } = ctx
    expect Spending { output: own, datum: _ } = info

    expect Some(inp) = transaction.find_input(transaction.inputs, own)
    let nft_in = is_impl_nft(inp.output.value, p)
    let nft_out =
      list.any(transaction.outputs, fn(o) { is_impl_nft(o.value, p) })

    nft_in && when r is {
      Update(h) -> {
        let outs =
          transaction.find_script_outputs(transaction.outputs, transaction.id)
        expect Some(o) = list.head(outs)
        expect Datum.InlineDatum(raw) = o.datum
        expect nd: ImplDatum = raw
        let op_ok =
          signer_matches(d.operator_pkh, transaction.extra_signatories)

        when d.step is {
          Mint -> {
            let new_hashes = d.meta_hashes ++
            [h]
            nft_out && nd.step == Process(0) && nd.meta_hashes == new_hashes && op_ok
          }
          Process(i) -> {
            let new_hashes = d.meta_hashes ++
            [h]
            nft_out && nd.step == Process(i + 1) && nd.meta_hashes == new_hashes && op_ok
          }
          _ -> False
        }
      }
      BurnR ->
        when d.step is {
          Process(_) ->
            signer_matches(d.operator_pkh, transaction.extra_signatories) && !nft_out
          _ -> False
        }
      _ -> False
    }
  }

  else(_) {
    False
  }
}
