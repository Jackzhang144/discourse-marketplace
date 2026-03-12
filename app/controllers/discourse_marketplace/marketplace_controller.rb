# frozen_string_literal: true

module DiscourseMarketplace
  class MarketplaceController < ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def mark_resolved
      DiscourseMarketplace::MarkResolved.call(
        params: { topic_id: params[:topic_id] },
        guardian: guardian
      ) do
        on_success do
          render json: success_json
        end
        on_failed_policy(:can_mark_resolved) do
          raise Discourse::InvalidAccess
        end
      end
    end
  end
end
