use aiken/hash.{Blake2b_224, Hash}
use aiken/interval
use aiken/list
use aiken/transaction.{ScriptContext, Spend, Transaction, ValidityRange}
use aiken/transaction/credential.{VerificationKey}

type Datum {
  lock_utime: POSIXTime,
  owner: VerificationKeyHash,
  beneficiary: VerificationKeyHash,
}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type POSIXTime =
  Int

validator {
  fn vesting(dataum: Datum, _redeemr: Void, ctx: ScriptContext) {
    when ctx.purpose is {
      Spend(_) ->
        // make sure this is a `spending` validator
        or {
          must_be_signed_by(ctx.transaction, dataum.owner),
          and {
            must_be_signed_by(ctx.transaction, dataum.beneficiary),
            must_start_after(ctx.transaction.validity_range, dataum.lock_utime),
          },
        }
      _ -> False
    }
  }
}

fn must_be_signed_by(transaction: Transaction, vk: VerificationKeyHash) -> Bool {
  list.has(transaction.extra_signatories, vk)
}

fn must_start_after(range: ValidityRange, lock_expiration_time: POSIXTime) -> Bool {
  interval.is_entirely_before(range, lock_expiration_time)
}

test must_start_after_succeed_when_lower_bound_is_after () {
  must_start_after(interval.after(2), 1)

}
