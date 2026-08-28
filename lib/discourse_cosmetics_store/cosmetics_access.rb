# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class CosmeticsAccess
    class << self
      def owned_item_ids(user:, items:)
        items = Array(items)
        return {} unless user
        return {} if items.empty?

        if DiscourseCosmeticsStore.base_integration_ready?
          return DiscourseUserCosmetics::Integration.owned_item_ids(user: user, items: items)
        end

        DiscourseUserCosmetics::UserItem
          .where(user_id: user.id, item_id: items.map(&:id))
          .pluck(:item_id)
          .index_with(true)
      end

      def entitled_item_ids(user:, items:)
        items = Array(items)
        return {} unless user
        return {} if items.empty?

        if DiscourseCosmeticsStore.base_integration_ready?
          return DiscourseUserCosmetics::Integration.entitled_item_ids(user: user, items: items)
        end

        legacy_entitled_item_ids(user: user, items: items)
      end

      def grant!(user:, item:)
        if DiscourseCosmeticsStore.base_integration_ready?
          return DiscourseUserCosmetics::Integration.grant!(user: user, item: item)
        end

        DiscourseUserCosmetics::UserItem.find_or_create_by!(user_id: user.id, item_id: item.id)
      end

      private

      def legacy_entitled_item_ids(user:, items:)
        item_ids = items.map(&:id)
        directly_owned_ids = owned_item_ids(user: user, items: items).keys.to_set

        groups_by_item = Hash.new { |hash, item_id| hash[item_id] = [] }
        DiscourseUserCosmetics::ItemGroup.where(item_id: item_ids).pluck(:item_id, :group_id).each do |item_id, group_id|
          groups_by_item[item_id] << group_id
        end

        relevant_group_ids = groups_by_item.values.flatten.uniq
        member_group_ids =
          if relevant_group_ids.empty?
            Set.new
          else
            GroupUser.where(user_id: user.id, group_id: relevant_group_ids).pluck(:group_id).to_set
          end

        locked_item_ids =
          if SiteSetting.discourse_cosmetics_store_enabled
            Catalog.locked_item_ids.map(&:to_i).to_set
          else
            Set.new
          end

        items.each_with_object({}) do |item, entitled|
          group_access = groups_by_item[item.id].any? { |group_id| member_group_ids.include?(group_id) }
          directly_owned = directly_owned_ids.include?(item.id)
          allowed =
            if locked_item_ids.include?(item.id)
              item.is_default? || directly_owned || group_access
            else
              item.is_default? || directly_owned || group_access || groups_by_item[item.id].empty?
            end

          entitled[item.id] = true if allowed
        end
      end
    end
  end
end
