# frozen_string_literal: true

# name: discourse-marketplace
# about: 二手交易帖子联系方式隐私保护插件
# version: 0.1
# authors: Jack
# url: https://github.com/your-repo/discourse-marketplace

register_svg_icon "phone"
register_svg_icon "check"

module ::DiscourseMarketplace
  PLUGIN_NAME = "discourse-marketplace"
  CONTACT_INFO_CUSTOM_FIELD = "marketplace_contact_info"
end

require_relative "lib/discourse_marketplace/engine"
require_relative "lib/discourse_marketplace/guardian_extensions"
require_relative "lib/discourse_marketplace/topic_view_serializer_extension"
require_relative "lib/discourse_marketplace/posts_controller_extension"

after_initialize do
  reloadable_patch do
    ::Guardian.prepend(DiscourseMarketplace::GuardianExtensions)
    ::TopicViewSerializer.prepend(DiscourseMarketplace::TopicViewSerializerExtension)
    ::PostsController.prepend(DiscourseMarketplace::PostsControllerExtension)
  end

  # 注册 Topic 自定义字段
  register_topic_custom_field_type(DiscourseMarketplace::CONTACT_INFO_CUSTOM_FIELD, :string)
end
