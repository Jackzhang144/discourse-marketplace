# frozen_string_literal: true

module DiscourseMarketplace
  module CategoryHelpers
    extend ActiveSupport::Concern

    def category_enabled?(category_id)
      return true if SiteSetting.marketplace_enabled_categories.blank?
      SiteSetting.marketplace_enabled_categories.include?(category_id)
    end
  end
end
