# frozen_string_literal: true

# name: discourse-marketplace
# about: 二手交易帖子联系方式隐私保护插件
# version: 0.1
# authors: Jack
# url: https://github.com/your-repo/discourse-marketplace

enabled_site_setting :marketplace_enabled

register_svg_icon "phone"
register_svg_icon "check"

module ::DiscourseMarketplace
  PLUGIN_NAME = "discourse-marketplace"
end

require_relative "lib/discourse_marketplace/engine"
require_relative "lib/discourse_marketplace/category_helpers"
require_relative "lib/discourse_marketplace/guardian_extensions"
require_relative "lib/discourse_marketplace/topic_view_serializer_extension"

after_initialize do
  reloadable_patch do
    ::Guardian.prepend(DiscourseMarketplace::GuardianExtensions)
    ::TopicViewSerializer.prepend(DiscourseMarketplace::TopicViewSerializerExtension)
  end
end
