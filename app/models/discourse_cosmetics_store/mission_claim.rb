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

# == Schema Information
#
# Table name: discourse_cosmetics_store_mission_claims
#
#  id                :bigint           not null, primary key
#  idempotency_key   :string(190)      not null
#  progress_at_claim :integer          not null
#  reward            :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  idx_dcs_mission_claim_idempotency  (idempotency_key) UNIQUE
#  idx_dcs_mission_claim_once         (mission_id,user_id) UNIQUE
#
