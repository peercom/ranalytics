# frozen_string_literal: true

require "local_analytics/version"
require "local_analytics/engine"
require "local_analytics/configuration"

module LocalAnalytics
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # ── Server-side tracking API ──────────────────────────────────────

    # Track a page view from server-side code.
    #
    #   LocalAnalytics.track_pageview(
    #     property_key: "main",
    #     url: "https://example.com/pricing",
    #     path: "/pricing",
    #     title: "Pricing",
    #     visitor_id: "abc123",
    #     ip: request.remote_ip,
    #     user_agent: request.user_agent,
    #     referrer: request.referrer
    #   )
    def track_pageview(property_key:, url:, path:, title: nil, visitor_id: nil, ip: nil, user_agent: nil, referrer: nil, metadata: {})
      Services::ServerTracker.track_pageview(
        property_key: property_key,
        url: url,
        path: path,
        title: title,
        visitor_id: visitor_id,
        ip: ip,
        user_agent: user_agent,
        referrer: referrer,
        metadata: metadata
      )
    end

    # Track a custom event from server-side code.
    #
    #   LocalAnalytics.track_event(
    #     property_key: "main",
    #     category: "purchase",
    #     action: "completed",
    #     name: "Premium Plan",
    #     value: 99.0,
    #     visitor_id: "abc123"
    #   )
    def track_event(property_key:, category:, action:, name: nil, value: nil, visitor_id: nil, ip: nil, user_agent: nil, metadata: {})
      Services::ServerTracker.track_event(
        property_key: property_key,
        category: category,
        action: action,
        name: name,
        value: value,
        visitor_id: visitor_id,
        ip: ip,
        user_agent: user_agent,
        metadata: metadata
      )
    end

    # Track a goal conversion from server-side code.
    #
    #   LocalAnalytics.track_conversion(
    #     property_key: "main",
    #     goal_key: "signup",
    #     visitor_id: "abc123",
    #     revenue: 49.0
    #   )
    def track_conversion(property_key:, goal_key:, visitor_id: nil, ip: nil, user_agent: nil, revenue: nil, metadata: {})
      Services::ServerTracker.track_conversion(
        property_key: property_key,
        goal_key: goal_key,
        visitor_id: visitor_id,
        ip: ip,
        user_agent: user_agent,
        revenue: revenue,
        metadata: metadata
      )
    end
  end
end
