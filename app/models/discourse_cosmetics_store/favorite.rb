# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Favorite < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_favorites"

    belongs_to :product,
               class_name: "::DiscourseCosmeticsStore::Product",
               inverse_of: :favorites
    belongs_to :user, class_name: "::User"

    validates :user_id, uniqueness: { scope: :product_id }
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_favorites
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  idx_dcs_favorites_user_product  (user_id,product_id) UNIQUE
#
