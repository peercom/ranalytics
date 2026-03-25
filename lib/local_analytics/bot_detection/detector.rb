# frozen_string_literal: true

module LocalAnalytics
  module BotDetection
    class Detector
      # Known bot user-agent fragments (subset — the browser gem handles most)
      BOT_PATTERNS = [
        /bot/i, /crawl/i, /spider/i, /slurp/i, /mediapartners/i,
        /googlebot/i, /bingbot/i, /yandexbot/i, /baiduspider/i,
        /facebookexternalhit/i, /twitterbot/i, /linkedinbot/i,
        /whatsapp/i, /telegrambot/i, /applebot/i,
        /semrushbot/i, /ahrefsbot/i, /dotbot/i, /mj12bot/i,
        /pingdom/i, /uptimerobot/i, /headlesschrome/i,
        /phantomjs/i, /selenium/i, /puppeteer/i,
        /wget/i, /curl/i, /python-requests/i, /httpie/i,
        /go-http-client/i, /java\//i, /okhttp/i
      ].freeze

      class << self
        def bot?(user_agent, ip = nil)
          return true if user_agent.blank?
          return true if bot_user_agent?(user_agent)
          return true if ignored_ip?(ip)

          false
        end

        private

        def bot_user_agent?(ua)
          # Use the browser gem's built-in bot detection first
          browser = Browser.new(ua)
          return true if browser.bot?

          # Additional patterns
          BOT_PATTERNS.any? { |pattern| ua.match?(pattern) }
        end

        def ignored_ip?(ip)
          return false if ip.blank?

          config = LocalAnalytics.configuration

          # Check exact IP matches
          return true if config.bot_ignore_ips.include?(ip)

          # Check CIDR ranges
          return false if config.bot_ignore_cidrs.empty?

          addr = IPAddr.new(ip)
          config.bot_ignore_cidrs.any? do |cidr|
            IPAddr.new(cidr).include?(addr)
          end
        rescue IPAddr::InvalidAddressError
          false
        end
      end
    end
  end
end
