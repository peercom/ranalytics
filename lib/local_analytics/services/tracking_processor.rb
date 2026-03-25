# frozen_string_literal: true

module LocalAnalytics
  module Services
    # Core tracking processor. Receives raw tracking payloads and creates
    # the appropriate database records (visitor, visit, pageview/event).
    # Called from ProcessTrackingJob.
    class TrackingProcessor
      def initialize(payload)
        @payload = payload.with_indifferent_access
      end

      def process
        return unless valid_payload?

        property = Property.active.find_by(key: @payload[:property_key])
        return unless property

        # Validate hostname if restrictions configured
        if @payload[:url].present?
          hostname = URI.parse(@payload[:url]).host rescue nil
          return unless property.allowed_hostname?(hostname)
        end

        visitor = find_or_create_visitor(property)
        visit = find_or_create_visit(property, visitor)

        case @payload[:type]
        when "pageview"
          create_pageview(property, visitor, visit)
        when "event"
          create_event(property, visitor, visit)
        when "conversion"
          create_conversion(property, visitor, visit)
        end

        # Check auto-goals after every tracking event
        check_automatic_goals(property, visitor, visit)
      rescue ActiveRecord::RecordNotUnique
        # Concurrent duplicate — safe to ignore
      rescue => e
        Rails.logger.error("[LocalAnalytics] Tracking error: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
      end

      private

      def valid_payload?
        @payload[:property_key].present? &&
          @payload[:type].present? &&
          %w[pageview event conversion].include?(@payload[:type])
      end

      def find_or_create_visitor(property)
        token = @payload[:visitor_id].presence || generate_cookieless_id
        visitor = property.visitors.find_or_initialize_by(visitor_token: token)

        if visitor.new_record?
          visitor.first_seen_at = Time.current
          visitor.save!
        end

        visitor
      end

      def find_or_create_visit(property, visitor)
        timeout = LocalAnalytics.configuration.visit_timeout
        recent_visit = visitor.visits
          .where(property: property)
          .where("ended_at > ? OR started_at > ?", timeout.ago, timeout.ago)
          .order(started_at: :desc)
          .first

        if recent_visit
          recent_visit.touch_ended_at!
          return recent_visit
        end

        # Mark visitor as returning if they've had previous visits
        visitor.mark_returning! if visitor.visits.where(property: property).exists?

        device_info = parse_device_info
        location_info = resolve_location
        referrer_info = parse_referrer

        property.visits.create!(
          visitor: visitor,
          visit_token: SecureRandom.hex(16),
          started_at: Time.current,
          ended_at: Time.current,
          bounced: true,
          ip: processed_ip,
          **device_info,
          **location_info,
          **referrer_info,
          **campaign_params
        )
      end

      def create_pageview(property, visitor, visit)
        pv = visit.pageviews.create!(
          property: property,
          visitor: visitor,
          url: @payload[:url],
          path: extract_path,
          title: @payload[:title],
          referrer: @payload[:referrer],
          viewed_at: Time.current,
          query_string: extract_query_string,
          page_load_time: @payload[:load_time],
          navigation_type: @payload[:nav_type] || "full",
          screen_resolution: @payload[:screen_resolution],
          viewport_size: @payload[:viewport_size],
          language: extract_language
        )

        # Update bounce: >1 pageview means not a bounce
        visit.update_bounce_status! if visit.pageviews.count > 1

        # Extract site search if applicable
        extract_site_search(property, visitor, visit, pv)

        pv
      end

      def create_event(property, visitor, visit)
        visit.events.create!(
          property: property,
          visitor: visitor,
          category: @payload[:category],
          action: @payload[:action],
          name: @payload[:name],
          value: @payload[:value],
          metadata: @payload[:metadata] || {}
        )
      end

      def create_conversion(property, visitor, visit)
        goal = property.goals.active.find_by(key: @payload[:goal_key])
        return unless goal

        # Only one conversion per goal per visit
        return if visit.conversions.exists?(goal: goal)

        visit.conversions.create!(
          property: property,
          visitor: visitor,
          goal: goal,
          revenue: @payload[:revenue] || goal.revenue_default,
          converted_at: Time.current
        )
      end

      def check_automatic_goals(property, visitor, visit)
        property.goals.active.find_each do |goal|
          next if visit.conversions.exists?(goal: goal)

          should_convert = case goal.goal_type
          when "url_match"
            last_pv = visit.pageviews.order(:viewed_at).last
            last_pv && goal.matches_pageview?(last_pv)
          when "event_match"
            visit.events.any? { |e| goal.matches_event?(e) }
          when "time_on_site"
            goal.matches_visit_duration?(visit.duration)
          when "pages_per_visit"
            goal.matches_pages_per_visit?(visit.pageviews.count)
          else
            false
          end

          if should_convert
            visit.conversions.create!(
              property: property,
              visitor: visitor,
              goal: goal,
              revenue: goal.revenue_default,
              converted_at: Time.current
            )
          end
        end
      end

      def extract_path
        path = @payload[:path].presence
        return path if path

        uri = URI.parse(@payload[:url])
        uri.path.presence || "/"
      rescue URI::InvalidURIError
        "/"
      end

      def extract_query_string
        return nil unless LocalAnalytics.configuration.store_query_parameters

        uri = URI.parse(@payload[:url])
        uri.query
      rescue URI::InvalidURIError
        nil
      end

      def extract_language
        lang = @payload[:language].presence
        return lang if lang

        accept = @payload[:accept_language].to_s
        accept.split(",").first&.split(";")&.first&.strip
      end

      def extract_site_search(property, visitor, visit, pageview)
        search_params = LocalAnalytics.configuration.site_search_params
        return if search_params.blank?

        query_string = URI.parse(pageview.url).query
        return if query_string.blank?

        params = Rack::Utils.parse_query(query_string)
        search_term = search_params.filter_map { |p| params[p] }.first
        return if search_term.blank?

        # Record as a search event
        visit.events.create!(
          property: property,
          visitor: visitor,
          category: "site_search",
          action: "search",
          name: search_term,
          metadata: { path: pageview.path }
        )
      rescue URI::InvalidURIError
        nil
      end

      def parse_device_info
        ua = @payload[:user_agent].to_s
        client = DeviceDetector.new(ua)
        browser = Browser.new(ua)

        {
          browser: client.name || "Unknown",
          browser_version: client.full_version,
          os: client.os_name || "Unknown",
          os_version: client.os_full_version,
          device_type: classify_device(client, browser),
          screen_resolution: @payload[:screen_resolution],
          viewport_size: @payload[:viewport_size],
          language: extract_language
        }
      end

      def classify_device(client, browser)
        return "bot" if browser.bot?

        case client.device_type
        when "desktop" then "desktop"
        when "smartphone" then "mobile"
        when "tablet" then "tablet"
        when "tv" then "tv"
        when "console" then "console"
        else
          browser.device.mobile? ? "mobile" : "desktop"
        end
      end

      def resolve_location
        return {} unless LocalAnalytics.configuration.enable_geo

        ip = @payload[:ip] || processed_ip
        return {} if ip.blank?

        geo = LocalAnalytics.configuration.geo_provider_instance.lookup(ip)
        {
          country: geo[:country],
          region: geo[:region],
          city: geo[:city]
        }
      rescue => e
        Rails.logger.warn("[LocalAnalytics] Geo lookup failed: #{e.message}")
        {}
      end

      def parse_referrer
        ref = @payload[:referrer].to_s
        return {} if ref.blank?

        uri = URI.parse(ref)
        host = uri.host

        source = classify_referrer_source(host)
        {
          referrer_url: ref.truncate(2048),
          referrer_host: host,
          referrer_source: source[:source],
          referrer_medium: source[:medium],
          search_engine: source[:search_engine],
          social_network: source[:social_network]
        }
      rescue URI::InvalidURIError
        {}
      end

      def classify_referrer_source(host)
        return { source: "direct", medium: "none" } if host.blank?

        search_engines = {
          "google" => /google\./,
          "bing" => /bing\.com/,
          "yahoo" => /yahoo\./,
          "duckduckgo" => /duckduckgo\.com/,
          "yandex" => /yandex\./,
          "baidu" => /baidu\.com/,
          "ecosia" => /ecosia\.org/
        }

        social_networks = {
          "facebook" => /facebook\.com|fb\.com/,
          "twitter" => /twitter\.com|t\.co|x\.com/,
          "linkedin" => /linkedin\.com/,
          "instagram" => /instagram\.com/,
          "youtube" => /youtube\.com|youtu\.be/,
          "reddit" => /reddit\.com/,
          "pinterest" => /pinterest\./,
          "tiktok" => /tiktok\.com/
        }

        search_engines.each do |name, pattern|
          if host.match?(pattern)
            return { source: name, medium: "search", search_engine: name }
          end
        end

        social_networks.each do |name, pattern|
          if host.match?(pattern)
            return { source: name, medium: "social", social_network: name }
          end
        end

        { source: host, medium: "referral" }
      end

      def campaign_params
        {
          utm_source: @payload[:utm_source],
          utm_medium: @payload[:utm_medium],
          utm_campaign: @payload[:utm_campaign],
          utm_term: @payload[:utm_term],
          utm_content: @payload[:utm_content]
        }.compact_blank
      end

      def processed_ip
        return nil unless LocalAnalytics.configuration.store_full_ip || LocalAnalytics.configuration.enable_geo

        @payload[:ip]
      end

      def generate_cookieless_id
        # In cookieless mode, generate a daily-rotating ID based on IP + UA
        # This provides approximate visitor counting without persistent identifiers
        data = "#{@payload[:ip]}|#{@payload[:user_agent]}|#{Date.current}"
        Digest::SHA256.hexdigest(data)[0..31]
      end
    end
  end
end
