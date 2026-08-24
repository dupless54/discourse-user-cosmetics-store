# frozen_string_literal: true

require "uri"

module ::DiscourseCosmeticsStore
  class Product < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_products"

    PRODUCT_TYPES = %w[item bundle].freeze
    HEX_COLOR_REGEX = /\A#[0-9a-fA-F]{3}([0-9a-fA-F]{3}([0-9a-fA-F]{2})?)?\z/

    belongs_to :created_by, class_name: "::User", optional: true
    has_many :product_items,
             -> { order(:position, :id) },
             class_name: "::DiscourseCosmeticsStore::ProductItem",
             dependent: :destroy,
             inverse_of: :product
    has_many :cosmetic_items,
             through: :product_items,
             source: :cosmetic_item
    has_many :purchases,
             class_name: "::DiscourseCosmeticsStore::Purchase",
             dependent: :restrict_with_error,
             inverse_of: :product
    has_many :favorites,
             class_name: "::DiscourseCosmeticsStore::Favorite",
             dependent: :destroy,
             inverse_of: :product
    has_many :gifts,
             class_name: "::DiscourseCosmeticsStore::Gift",
             dependent: :restrict_with_error,
             inverse_of: :product

    validates :name, presence: true, length: { maximum: 120 }
    validates :slug, presence: true, uniqueness: true, length: { maximum: 140 }
    validates :description, length: { maximum: 4000 }, allow_blank: true
    validates :product_type, inclusion: { in: PRODUCT_TYPES }
    validates :price,
              :sort_order,
              :purchase_count,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :rarity_label, length: { maximum: 40 }, allow_blank: true
    validates :rarity_color, format: { with: HEX_COLOR_REGEX }, allow_blank: true
    validates :collection_name, length: { maximum: 120 }, allow_blank: true
    validates :collection_slug, length: { maximum: 140 }, allow_blank: true
    validate :availability_window_is_valid
    validate :external_urls_are_safe

    before_validation :ensure_slug
    before_validation :normalize_tags
    before_validation :normalize_collection

    scope :ordered, -> { order(editor_pick: :desc, featured: :desc, sort_order: :asc, id: :desc) }
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

    def bundle?
      product_type == "bundle"
    end

    private

    def ensure_slug
      return if name.blank?

      base = Slug.for(slug.presence || name).presence || "cosmetic"
      candidate = base[0, 140]
      suffix = 2

      while self.class.where.not(id: id).exists?(slug: candidate)
        trailer = "-#{suffix}"
        candidate = "#{base[0, 140 - trailer.length]}#{trailer}"
        suffix += 1
      end

      self.slug = candidate
    end

    def normalize_tags
      source = tags.is_a?(String) ? tags.split(",") : Array(tags)
      self.tags =
        source
          .filter_map { |value| Slug.for(value.to_s.strip).presence }
          .uniq
          .first(12)
    end

    def availability_window_is_valid
      return if available_from.blank? || available_until.blank? || available_until > available_from

      errors.add(:available_until, :greater_than, count: available_from)
    end

    def external_urls_are_safe
      %i[card_image_url hero_image_url preview_background_url collection_image_url].each do |attribute|
        value = public_send(attribute).to_s.strip
        next if value.blank?

        begin
          uri = URI.parse(value)
          valid = %w[http https].include?(uri.scheme&.downcase) && uri.host.present? && uri.userinfo.blank?
          errors.add(attribute, :invalid) unless valid
        rescue URI::InvalidURIError
          errors.add(attribute, :invalid)
        end
      end
    end

    def normalize_collection
      self.collection_name = collection_name.to_s.strip.presence
      source = collection_slug.presence || collection_name
      self.collection_slug = Slug.for(source.to_s).presence if source.present?
      self.collection_slug = nil if collection_name.blank?
    end
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_products
#
#  id                     :bigint           not null, primary key
#  available_from         :datetime
#  available_until        :datetime
#  card_image_url         :string(1000)
#  description            :text
#  editor_pick            :boolean          default(FALSE), not null
#  enabled                :boolean          default(TRUE), not null
#  exclusive              :boolean          default(TRUE), not null
#  featured               :boolean          default(FALSE), not null
#  hero_image_url         :string(1000)
#  name                   :string(120)      not null
#  preview_background_url :string(1000)
#  price                  :integer          default(0), not null
#  product_type           :string(20)       default("item"), not null
#  purchase_count         :integer          default(0), not null
#  rarity_color           :string(20)
#  rarity_label           :string(40)
#  slug                   :string(140)      not null
#  sort_order             :integer          default(0), not null
#  tags                   :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  created_by_id          :integer
#
# Indexes
#
#  idx_dcs_products_catalog  (enabled,featured,editor_pick,sort_order)
#  idx_dcs_products_slug     (slug) UNIQUE
#  idx_dcs_products_tags     (tags) USING gin
#
