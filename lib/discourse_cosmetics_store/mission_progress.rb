# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class MissionProgress
    def self.for(user, mission)
      return 0 unless user

      case mission.metric
      when "posts_created"
        user.user_stat&.post_count.to_i
      when "topics_created"
        user.user_stat&.topic_count.to_i
      when "likes_received"
        user.user_stat&.likes_received.to_i
      when "days_visited"
        user.user_stat&.days_visited.to_i
      when "trust_level"
        user.trust_level.to_i
      when "badges_earned"
        UserBadge.where(user_id: user.id).count
      when "account_age_days"
        [(Time.zone.today - user.created_at.to_date).to_i, 0].max
      else
        0
      end
    end
  end
end
