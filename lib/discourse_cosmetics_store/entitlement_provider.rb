# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class EntitlementProvider
    def self.call(user:, items:, **_kwargs)
      return nil unless SiteSetting.discourse_cosmetics_store_enabled
      return nil unless user

      items = Array(items)
      locked_item_ids = Catalog.locked_item_ids.map(&:to_i).to_set
      locked_items = items.select { |item| locked_item_ids.include?(item.id) }
      return nil if locked_items.empty?

      item_ids = locked_items.map(&:id)
      groups_by_item = Hash.new { |hash, item_id| hash[item_id] = [] }
      DiscourseUserCosmetics::ItemGroup.where(item_id: item_ids).pluck(:item_id, :group_id).each do |item_id, group_id|
        groups_by_item[item_id] << group_id
      end

      relevant_group_ids = groups_by_item.values.flatten.uniq
      member_group_ids =
        if relevant_group_ids.empty?
          Set.new
        else
          GroupUser
            .where(user_id: user.id, group_id: relevant_group_ids)
            .pluck(:group_id)
            .to_set
        end

      directly_owned_ids =
        DiscourseUserCosmetics::Integration
          .owned_item_ids(user: user, items: locked_items)
          .keys
          .to_set

      locked_items.each_with_object({}) do |item, decisions|
        group_access = groups_by_item[item.id].any? { |group_id| member_group_ids.include?(group_id) }
        decisions[item.id] = item.is_default? || directly_owned_ids.include?(item.id) || group_access
      end
    end
  end
end
