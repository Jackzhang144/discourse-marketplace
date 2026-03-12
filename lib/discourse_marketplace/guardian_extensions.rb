# frozen_string_literal: true

module DiscourseMarketplace
  module GuardianExtensions
    def can_mark_topic_resolved?(topic)
      return false unless authenticated?

      # Staff 可以标记
      return true if is_staff?
      # 作者可以标记
      topic.user_id == current_user.id
    end
  end
end
