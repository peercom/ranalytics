# frozen_string_literal: true

module LocalAnalytics
  # Handles incoming tracking requests from the JS tracker.
  # This endpoint must be fast — it enqueues processing to a background job
  # and returns immediately.
  class TrackingController < ActionController::Base
    skip_before_action :verify_authenticity_token
    after_action :set_cors_headers

    # POST /analytics/t
    # Accepts JSON payload from the JS tracker.
    def create
      if should_ignore_request?
        head :no_content
        return
      end

      payload = parse_payload
      return head(:bad_request) unless payload && payload[:property_key].present?

      ProcessTrackingJob.perform_later(
        payload.merge(
          ip: anonymized_ip,
          user_agent: request.user_agent,
          accept_language: request.headers["Accept-Language"]
        ).deep_stringify_keys
      )

      head :no_content
    end

    # GET /analytics/t — 1x1 transparent GIF for noscript tracking
    def pixel
      if should_ignore_request?
        send_pixel
        return
      end

      payload = {
        type: "pageview",
        property_key: params[:pk],
        url: params[:u],
        path: params[:p],
        title: params[:t],
        referrer: params[:r],
        visitor_id: params[:vid]
      }

      ProcessTrackingJob.perform_later(
        payload.merge(
          ip: anonymized_ip,
          user_agent: request.user_agent,
          accept_language: request.headers["Accept-Language"]
        ).deep_stringify_keys
      )

      send_pixel
    end

    private

    def parse_payload
      body = request.body.read
      body = request.raw_post if body.blank?

      if body.present?
        parsed = JSON.parse(body)
        return parsed.symbolize_keys if parsed.is_a?(Hash)
      end

      # Fall back to Rails params (handles middleware-parsed JSON)
      allowed = %i[type property_key url path title referrer visitor_id
                   category action name value metadata goal_key revenue
                   utm_source utm_medium utm_campaign utm_term utm_content
                   screen_resolution viewport_size language load_time nav_type]
      extracted = params.to_unsafe_h.symbolize_keys.slice(*allowed)
      extracted.presence
    rescue JSON::ParserError
      nil
    end

    def anonymized_ip
      ip = request.remote_ip
      return nil if ip.blank?

      if LocalAnalytics.configuration.ip_anonymization
        Services::IpAnonymizer.anonymize(ip)
      else
        ip
      end
    end

    def should_ignore_request?
      config = LocalAnalytics.configuration

      # Respect DNT
      if config.respect_dnt && request.headers["DNT"] == "1"
        return true
      end

      # Bot filtering
      if config.bot_filtering && BotDetection::Detector.bot?(request.user_agent, request.remote_ip)
        return true
      end

      # Custom exclusion
      config.exclude_request.call(request)
    end

    def send_pixel
      # 1x1 transparent GIF
      gif = Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")
      send_data gif, type: "image/gif", disposition: "inline"
    end

    def set_cors_headers
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"] || "*"
      response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Content-Type"
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    end
  end
end
