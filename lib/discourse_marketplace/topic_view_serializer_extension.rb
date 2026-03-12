# frozen_string_literal: true

module DiscourseMarketplace
  module TopicViewSerializerExtension
    def self.prepended(base)
      base.attributes :marketplace_contact_info, :can_view_marketplace_contact_info,
                      :can_mark_topic_resolved, :marketplace_resolved_category_id
    end

    def marketplace_contact_info
      return nil unless category_enabled?(object.topic.category_id)

      contact_info = object.topic.custom_fields[DiscourseMarketplace::CONTACT_INFO_CUSTOM_FIELD]

      # 检查权限
      return contact_info if scope.can_view_marketplace_contact_info?(object.topic)

      # 如果帖子已标记为已解决，也返回空
      return nil if object.topic.category_id == SiteSetting.marketplace.resolved_category_id.to_i

      nil
    end

    def can_view_marketplace_contact_info
      scope.can_view_marketplace_contact_info?(object.topic)
    end

    def can_mark_topic_resolved
      return false unless SiteSetting.marketplace.resolved_category_id.present?
      return false unless category_enabled?(object.topic.category_id)

      # 已经是已解决分类的帖子不能再次标记
      return false if object.topic.category_id == SiteSetting.marketplace.resolved_category_id.to_i

      scope.can_mark_topic_resolved?(object.topic)
    end

    def marketplace_resolved_category_id
      SiteSetting.marketplace.resolved_category_id.to_i
    end

    private

    def category_enabled?(category_id)
      return true if SiteSetting.marketplace.enabled_categories.blank?
      SiteSetting.marketplace.enabled_categories.include?(category_id)
    end
  end
end
