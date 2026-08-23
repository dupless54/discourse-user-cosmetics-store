# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Wallet < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_wallets"

    belongs_to :user, class_name: "::User"
    has_many :ledger_entries,
             class_name: "::DiscourseCosmeticsStore::LedgerEntry",
             dependent: :restrict_with_error,
             inverse_of: :wallet

    validates :user_id, uniqueness: true
    validates :balance,
              :lifetime_earned,
              :lifetime_spent,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
