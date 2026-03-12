# frozen_string_literal: true

module DiscourseMarketplace
  module TopicViewSerializerExtension
    def self.prepended(base)
      base.attributes :can_mark_topic_resolved
    end

    def can_mark_topic_resolved
      return false unless SiteSetting.marketplace_enabled
      return false unless category_enabled?(object.topic.category_id)

      scope.can_mark_topic_resolved?(object.topic)
    end

    private

    def category_enabled?(category_id)
      return true if SiteSetting.marketplace_enabled_categories.blank?
      SiteSetting.marketplace_enabled_categories.include?(category_id)
    end
  end
end
