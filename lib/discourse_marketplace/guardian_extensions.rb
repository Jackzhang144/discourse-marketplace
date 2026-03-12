# frozen_string_literal: true

module DiscourseMarketplace
  module GuardianExtensions
    def can_view_marketplace_contact_info?(topic)
      return false unless authenticated?

      # 作者可以查看
      return true if topic.user_id == current_user.id
      # Staff 可以查看
      return true if is_staff?

      true
    end

    def can_mark_topic_resolved?(topic)
      return false unless authenticated?
      return false unless SiteSetting.marketplace_resolved_category_id.present?

      # Staff 可以标记
      return true if is_staff?
      # 作者可以标记
      topic.user_id == current_user.id
    end

    def can_edit_marketplace_contact_info?(topic)
      return false unless authenticated?

      # 作者可以编辑
      return true if topic.user_id == current_user.id
      # Staff 可以编辑
      is_staff?
    end
  end
end
