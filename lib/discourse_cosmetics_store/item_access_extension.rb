# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  module ItemAccessExtension
    def usable_by?(user)
      return super unless SiteSetting.discourse_cosmetics_store_enabled
      return super unless DiscourseCosmeticsStore::Catalog.item_locked?(id)
      return false unless user
      return true if is_default?
      return true if item_groups.where(group_id: user.group_ids).exists?

      user_items.where(user_id: user.id).exists?
    end
  end
end
