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

# == Schema Information
#
# Table name: discourse_cosmetics_store_ledger_entries
#
#  id              :bigint           not null, primary key
#  amount          :bigint           not null
#  balance_after   :bigint           not null
#  entry_type      :string(30)       not null
#  idempotency_key :string(190)      not null
#  reason          :string(500)
#  reference_type  :string(60)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :integer
#  reference_id    :integer
#  user_id         :integer          not null
#  wallet_id       :integer          not null
#
# Indexes
#
#  idx_dcs_ledger_idempotency   (idempotency_key) UNIQUE
#  idx_dcs_ledger_user_created  (user_id,created_at)
#
