# frozen_string_literal: true

require "securerandom"

module ::DiscourseCosmeticsStore
  class WalletService
    class InsufficientBalance < StandardError; end
    class BalanceLimitExceeded < StandardError; end

    def self.fetch(user)
      wallet = Wallet.find_by(user_id: user.id)
      return wallet if wallet

      Wallet.transaction(requires_new: true) do
        wallet = Wallet.create!(
          user_id: user.id,
          balance: starting_balance,
          lifetime_earned: starting_balance,
          lifetime_spent: 0,
        )

        if starting_balance.positive?
          LedgerEntry.create!(
            wallet_id: wallet.id,
            user_id: user.id,
            amount: starting_balance,
            balance_after: starting_balance,
            entry_type: "starting_balance",
            idempotency_key: "wallet-start:#{user.id}",
            reason: "Başlangıç bakiyesi",
          )
        end

        wallet
      end
    rescue ActiveRecord::RecordNotUnique
      Wallet.find_by!(user_id: user.id)
    end

    def self.credit!(user:, amount:, entry_type:, idempotency_key:, reason: nil,
                    reference_type: nil, reference_id: nil, created_by: nil)
      change!(
        user: user,
        amount: amount.to_i.abs,
        entry_type: entry_type,
        idempotency_key: idempotency_key,
        reason: reason,
        reference_type: reference_type,
        reference_id: reference_id,
        created_by: created_by,
      )
    end

    def self.debit!(user:, amount:, entry_type:, idempotency_key:, reason: nil,
                   reference_type: nil, reference_id: nil, created_by: nil)
      change!(
        user: user,
        amount: -amount.to_i.abs,
        entry_type: entry_type,
        idempotency_key: idempotency_key,
        reason: reason,
        reference_type: reference_type,
        reference_id: reference_id,
        created_by: created_by,
      )
    end

    def self.adjust!(user:, amount:, reason:, created_by:)
      change!(
        user: user,
        amount: amount.to_i,
        entry_type: "admin_adjustment",
        idempotency_key: "admin:#{created_by.id}:#{user.id}:#{SecureRandom.uuid}",
        reason: reason,
        created_by: created_by,
      )
    end

    def self.change!(user:, amount:, entry_type:, idempotency_key:, reason: nil,
                     reference_type: nil, reference_id: nil, created_by: nil)
      existing = LedgerEntry.find_by(idempotency_key: idempotency_key)
      return existing.wallet if existing

      Wallet.transaction do
        wallet = fetch(user)
        wallet.lock!

        existing = LedgerEntry.find_by(idempotency_key: idempotency_key)
        next existing.wallet if existing

        next_balance = wallet.balance.to_i + amount.to_i
        raise InsufficientBalance if next_balance.negative?
        raise BalanceLimitExceeded if next_balance > max_balance

        earned = amount.positive? ? amount : 0
        spent = amount.negative? ? amount.abs : 0
        wallet.update!(
          balance: next_balance,
          lifetime_earned: wallet.lifetime_earned.to_i + earned,
          lifetime_spent: wallet.lifetime_spent.to_i + spent,
        )

        LedgerEntry.create!(
          wallet_id: wallet.id,
          user_id: user.id,
          amount: amount,
          balance_after: next_balance,
          entry_type: entry_type,
          reference_type: reference_type,
          reference_id: reference_id,
          idempotency_key: idempotency_key,
          reason: reason,
          created_by_id: created_by&.id,
        )

        wallet
      end
    rescue ActiveRecord::RecordNotUnique
      LedgerEntry.find_by!(idempotency_key: idempotency_key).wallet
    end

    def self.starting_balance
      SiteSetting.discourse_cosmetics_store_starting_balance.to_i.clamp(0, max_balance)
    end

    def self.max_balance
      SiteSetting.discourse_cosmetics_store_max_balance.to_i.clamp(1_000, 2_000_000_000)
    end
  end
end
