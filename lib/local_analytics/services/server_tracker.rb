# frozen_string_literal: true

module LocalAnalytics
  module Services
    # Server-side tracking API. Used by host app Ruby code to record
    # pageviews, events, and conversions without the JS tracker.
    class ServerTracker
      class << self
        def track_pageview(property_key:, url:, path:, title: nil, visitor_id: nil, ip: nil, user_agent: nil, referrer: nil, metadata: {})
          enqueue(
            type: "pageview",
            property_key: property_key,
            url: url,
            path: path,
            title: title,
            visitor_id: visitor_id || generate_visitor_id(ip, user_agent),
            ip: maybe_anonymize(ip),
            user_agent: user_agent,
            referrer: referrer,
            metadata: metadata
          )
        end

        def track_event(property_key:, category:, action:, name: nil, value: nil, visitor_id: nil, ip: nil, user_agent: nil, metadata: {})
          enqueue(
            type: "event",
            property_key: property_key,
            category: category,
            action: action,
            name: name,
            value: value,
            visitor_id: visitor_id || generate_visitor_id(ip, user_agent),
            ip: maybe_anonymize(ip),
            user_agent: user_agent,
            metadata: metadata
          )
        end

        def track_conversion(property_key:, goal_key:, visitor_id: nil, ip: nil, user_agent: nil, revenue: nil, metadata: {})
          enqueue(
            type: "conversion",
            property_key: property_key,
            goal_key: goal_key,
            visitor_id: visitor_id || generate_visitor_id(ip, user_agent),
            ip: maybe_anonymize(ip),
            user_agent: user_agent,
            revenue: revenue,
            metadata: metadata
          )
        end

        private

        def enqueue(payload)
          ProcessTrackingJob.perform_later(payload.deep_stringify_keys)
        end

        def maybe_anonymize(ip)
          return nil if ip.blank?

          if LocalAnalytics.configuration.ip_anonymization
            IpAnonymizer.anonymize(ip)
          else
            ip
          end
        end

        def generate_visitor_id(ip, user_agent)
          data = "#{ip}|#{user_agent}|server"
          Digest::SHA256.hexdigest(data)[0..31]
        end
      end
    end
  end
end
