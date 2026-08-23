# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class MissionClaim < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_mission_claims"

    belongs_to :mission,
               class_name: "::DiscourseCosmeticsStore::Mission",
               inverse_of: :claims
    belongs_to :user, class_name: "::User"

    validates :user_id, uniqueness: { scope: :mission_id }
    validates :progress_at_claim, :reward,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :idempotency_key, presence: true, uniqueness: true, length: { maximum: 190 }
  end
end
