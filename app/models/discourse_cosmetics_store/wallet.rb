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

# == Schema Information
#
# Table name: discourse_cosmetics_store_wallets
#
#  id              :bigint           not null, primary key
#  balance         :bigint           default(0), not null
#  lifetime_earned :bigint           default(0), not null
#  lifetime_spent  :bigint           default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  idx_dcs_wallets_user  (user_id) UNIQUE
#
