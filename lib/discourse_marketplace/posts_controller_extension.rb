# frozen_string_literal: true

module DiscourseMarketplace
  module PostsControllerExtension
    def self.prepended(base)
      base.class_eval do
        alias_method :original_create, :create
        alias_method :create, :create_with_marketplace
      end
    end

    def create_with_marketplace
      # 先执行原来的创建逻辑
      original_create

      # 保存成功后，处理联系方式
      if @post && @post.errors.blank? && params[:marketplace_contact_info].present?
        topic = @post.topic
        if topic && category_enabled?(topic.category_id)
          topic.custom_fields[DiscourseMarketplace::CONTACT_INFO_CUSTOM_FIELD] =
            params[:marketplace_contact_info]
          topic.save_custom_fields
        end
      end
    end

    private

    def category_enabled?(category_id)
      return true if SiteSetting.marketplace_enabled_categories.blank?
      SiteSetting.marketplace_enabled_categories.include?(category_id)
    end
  end
end
