# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::WalletService do
  let(:user) { Fabricate(:user) }
  let(:idempotency_key) { "gift:spec:#{user.id}:42" }

  before do
    SiteSetting.discourse_cosmetics_store_starting_balance = 100
  end

  it "records gift debits with durable idempotent ledger semantics" do
    wallet =
      described_class.debit!(
        user: user,
        amount: 25,
        entry_type: "gift",
        idempotency_key: idempotency_key,
        reason: "Gift regression spec",
        reference_type: "DiscourseCosmeticsStore::Product",
        reference_id: 42,
      )

    entry = DiscourseCosmeticsStore::LedgerEntry.find_by!(idempotency_key: idempotency_key)

    expect(wallet.reload.balance).to eq(75)
    expect(wallet.lifetime_spent).to eq(25)
    expect(entry.entry_type).to eq("gift")
    expect(entry.amount).to eq(-25)
    expect(entry.balance_after).to eq(75)

    described_class.debit!(
      user: user,
      amount: 25,
      entry_type: "gift",
      idempotency_key: idempotency_key,
      reason: "Duplicate gift retry",
      reference_type: "DiscourseCosmeticsStore::Product",
      reference_id: 42,
    )

    expect(wallet.reload.balance).to eq(75)
    expect(
      DiscourseCosmeticsStore::LedgerEntry.where(idempotency_key: idempotency_key).count,
    ).to eq(1)
  end
end
