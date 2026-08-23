# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class MissionClaimService
    class Unavailable < StandardError; end
    class Incomplete < StandardError; end
    class AlreadyClaimed < StandardError; end

    attr_reader :user, :mission, :wallet, :claim, :progress

    def initialize(user:, mission:)
      @user = user
      @mission = mission
    end

    def call
      Mission.transaction do
        @mission = Mission.lock.find(mission.id)
        raise Unavailable unless SiteSetting.discourse_cosmetics_store_missions_enabled && @mission.available_now?
        raise AlreadyClaimed if MissionClaim.where(mission_id: @mission.id, user_id: user.id).exists?

        @progress = MissionProgress.for(user, @mission)
        raise Incomplete if @progress < @mission.target

        idempotency_key = "mission:#{@mission.id}:#{user.id}"
        @claim = MissionClaim.create!(
          mission_id: @mission.id,
          user_id: user.id,
          progress_at_claim: @progress,
          reward: @mission.reward,
          idempotency_key: idempotency_key,
        )
        @wallet = WalletService.credit!(
          user: user,
          amount: @mission.reward,
          entry_type: "mission_reward",
          idempotency_key: idempotency_key,
          reason: @mission.name,
          reference_type: "DiscourseCosmeticsStore::Mission",
          reference_id: @mission.id,
        )
      end

      self
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyClaimed
    end
  end
end
