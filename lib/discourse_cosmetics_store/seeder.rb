# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Seeder
    DEFAULT_MISSIONS = [
      {
        key: "ilk-gonderi",
        name: "İlk adım",
        description: "Forumda ilk gönderini paylaş.",
        metric: "posts_created",
        target: 1,
        reward: 25,
        icon: "✦",
        sort_order: 10,
      },
      {
        key: "on-gonderi",
        name: "Sohbete katıl",
        description: "Toplam 10 gönderiye ulaş.",
        metric: "posts_created",
        target: 10,
        reward: 75,
        icon: "💬",
        sort_order: 20,
      },
      {
        key: "uc-konu",
        name: "Konu üreticisi",
        description: "Toplam 3 konu oluştur.",
        metric: "topics_created",
        target: 3,
        reward: 100,
        icon: "▤",
        sort_order: 30,
      },
      {
        key: "yedi-gun",
        name: "Düzenli ziyaretçi",
        description: "Forumu toplam 7 gün ziyaret et.",
        metric: "days_visited",
        target: 7,
        reward: 125,
        icon: "◷",
        sort_order: 40,
      },
      {
        key: "on-begeni",
        name: "Topluluğun favorisi",
        description: "Gönderilerine toplam 10 beğeni al.",
        metric: "likes_received",
        target: 10,
        reward: 150,
        icon: "♥",
        sort_order: 50,
      },
    ].freeze

    def self.seed_defaults!
      return unless ActiveRecord::Base.connection.table_exists?(:discourse_cosmetics_store_missions)

      DEFAULT_MISSIONS.each do |attributes|
        Mission.find_or_create_by!(key: attributes[:key]) { |mission| mission.assign_attributes(attributes) }
      end
    rescue StandardError => error
      Rails.logger.warn(
        "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] default mission seed failed: " \
          "#{error.class}: #{error.message}",
      )
    end
  end
end
