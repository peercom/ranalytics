# frozen_string_literal: true

require "device_detector"
require "browser"
require "csv"

module LocalAnalytics
  class Engine < ::Rails::Engine
    isolate_namespace LocalAnalytics

    # Autoload lib classes (services, reports, geo, bot detection)
    config.autoload_paths += %W[
      #{root}/lib
    ]

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    initializer "local_analytics.assets" do |app|
      app.config.assets.precompile += %w[
        local_analytics/tracker.js
        local_analytics/admin.js
        local_analytics/admin.css
      ] if app.config.respond_to?(:assets)
    end

    initializer "local_analytics.append_routes" do |app|
      # Allow the engine to be mounted; routes are defined in config/routes.rb
    end

    initializer "local_analytics.middleware" do |app|
      # We intentionally do NOT add Rack middleware for tracking.
      # Tracking is handled via the JS tracker hitting the tracking controller,
      # or via the server-side API. This keeps the middleware stack clean and
      # avoids adding latency to every request in the host app.
    end

    initializer "local_analytics.configure_geo" do
      ActiveSupport.on_load(:active_record) do
        # Ensure geo provider is available when models load
      end
    end

    # Provide view helpers to host app
    initializer "local_analytics.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper LocalAnalytics::TrackingHelper
      end

      ActiveSupport.on_load(:action_controller_api) do
        # API controllers don't need view helpers
      end
    end
  end
end
