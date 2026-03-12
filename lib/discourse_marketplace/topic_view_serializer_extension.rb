# frozen_string_literal: true

module DiscourseMarketplace
  module TopicViewSerializerExtension
    def self.prepended(base)
      base.attributes :can_mark_topic_resolved, :marketplace_resolved_category_id
    end

    def can_mark_topic_resolved
      return false unless SiteSetting.marketplace_resolved_category_id.present?
      return false unless category_enabled?(object.topic.category_id)

      # 已经是已解决分类的帖子不能再次标记
      return false if object.topic.category_id == SiteSetting.marketplace_resolved_category_id.to_i

      scope.can_mark_topic_resolved?(object.topic)
    end

    def marketplace_resolved_category_id
      SiteSetting.marketplace_resolved_category_id.to_i
    end

    private

    def category_enabled?(category_id)
      return true if SiteSetting.marketplace_enabled_categories.blank?
      SiteSetting.marketplace_enabled_categories.include?(category_id)
    end
  end
end
