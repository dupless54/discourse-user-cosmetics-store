# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Mission < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_missions"

    METRICS = %w[
      posts_created
      topics_created
      likes_received
      days_visited
      trust_level
      badges_earned
      account_age_days
    ].freeze

    has_many :claims,
             class_name: "::DiscourseCosmeticsStore::MissionClaim",
             dependent: :restrict_with_error,
             inverse_of: :mission

    validates :key, presence: true, uniqueness: true, length: { maximum: 100 }
    validates :name, presence: true, length: { maximum: 120 }
    validates :description, length: { maximum: 500 }, allow_blank: true
    validates :metric, inclusion: { in: METRICS }
    validates :target, numericality: { only_integer: true, greater_than: 0 }
    validates :reward, :sort_order,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :icon, length: { maximum: 20 }, allow_blank: true
    validate :availability_window_is_valid

    before_validation :normalize_key

    scope :ordered, -> { order(:sort_order, :id) }
    scope :available,
          -> do
            now = Time.zone.now
            where(enabled: true)
              .where("available_from IS NULL OR available_from <= ?", now)
              .where("available_until IS NULL OR available_until >= ?", now)
          end

    def available_now?
      enabled? && (available_from.blank? || available_from <= Time.zone.now) &&
        (available_until.blank? || available_until >= Time.zone.now)
    end

    private

    def normalize_key
      self.key = Slug.for(key.presence || name).presence
    end

    def availability_window_is_valid
      return if available_from.blank? || available_until.blank? || available_until > available_from

      errors.add(:available_until, :greater_than, count: available_from)
    end
  end
end
