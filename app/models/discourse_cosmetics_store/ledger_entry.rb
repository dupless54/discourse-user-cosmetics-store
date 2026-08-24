# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class LedgerEntry < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_ledger_entries"

    ENTRY_TYPES = %w[starting_balance mission_reward purchase payment admin_adjustment refund].freeze

    belongs_to :wallet,
               class_name: "::DiscourseCosmeticsStore::Wallet",
               inverse_of: :ledger_entries
    belongs_to :user, class_name: "::User"
    belongs_to :created_by, class_name: "::User", optional: true

    validates :entry_type, inclusion: { in: ENTRY_TYPES }
    validates :idempotency_key, presence: true, uniqueness: true, length: { maximum: 190 }
    validates :amount, :balance_after, numericality: { only_integer: true }
    validates :reason, length: { maximum: 500 }, allow_blank: true
  end
end
