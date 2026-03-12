# frozen_string_literal: true

module DiscourseMarketplace
  class MarkResolved
    include Service::Base

    params do
      attribute :topic_id, :integer
      validates :topic_id, presence: true
    end

    model :topic

    policy :can_mark_resolved

    step :update_category
    step :clear_contact_info
    step :publish_event
  end

  private

  def can_mark_resolved(topic:, guardian:)
    guardian.can_mark_topic_resolved?(topic)
  end

  def update_category(topic:)
    resolved_category_id = SiteSetting.marketplace.resolved_category_id.to_i
    topic.update!(category_id: resolved_category_id)
  end

  def clear_contact_info(topic:)
    topic.custom_fields.delete(DiscourseMarketplace::CONTACT_INFO_CUSTOM_FIELD)
    topic.save_custom_fields
  end

  def publish_event(topic:)
    DiscourseEvent.trigger(:marketplace_topic_resolved, topic)
  end
end
