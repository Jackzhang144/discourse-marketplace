# frozen_string_literal: true

DiscourseMarketplace::Engine.routes.draw do
  post "/mark_resolved" => "marketplace#mark_resolved"
end

Discourse::Application.routes.draw { mount DiscourseMarketplace::Engine, at: "marketplace" }
