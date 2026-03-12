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

    step :remove_contact_bbcode
    step :publish_event
  end

  private

  def can_mark_resolved(topic:, guardian:)
    return false if !SiteSetting.marketplace_enabled
    return false if !topic.category_id.in?(SiteSetting.marketplace_enabled_categories.map(&:to_i))
    guardian.can_mark_topic_resolved?(topic)
  end

  def remove_contact_bbcode(topic:, guardian:)
    post = topic.ordered_posts.first
    return if post.blank?

    raw = post.raw
    # 移除 [contact]...[/contact] BBCode
    new_raw = raw.gsub(/\[contact\](.*?)\[\/contact\]/mi, "")

    # 如果有内容被移除，添加提示信息
    if new_raw != raw
      # 清理多余的空白
      new_raw = new_raw.squeeze("\n").strip
      # 添加提示块
      hint_text = I18n.t("marketplace.contact_hidden")
      new_raw = "#{new_raw}\n\n> #{hint_text}"
    end

    # 更新帖子
    post.update!(raw: new_raw, last_editor_id: guardian.user.id)
  end

  def publish_event(topic:)
    DiscourseEvent.trigger(:marketplace_topic_resolved, topic)
  end
end
