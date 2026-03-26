# frozen_string_literal: true

module LocalAnalytics
  module BotDetection
    class Detector
      BOT_PATTERNS = [
        # ── Generic bot indicators ──────────────────────────────────
        /bot\b/i, /crawl/i, /spider/i, /slurp/i, /archiver/i, /transcoder/i,
        /fetch/i, /scraper/i, /checker/i, /monitor/i, /scanner/i,

        # ── Search engines ──────────────────────────────────────────
        /googlebot/i, /bingbot/i, /yandexbot/i, /baiduspider/i,
        /duckduckbot/i, /seznambot/i, /exabot/i, /sogou/i,
        /ia_archiver/i, /applebot/i,

        # ── AI crawlers ─────────────────────────────────────────────
        /gptbot/i, /chatgpt/i, /oai-searchbot/i,
        /claudebot/i, /claude-web/i, /anthropic/i,
        /bytespider/i, /bytedance/i, /petalbot/i,
        /ccbot/i, /cohere-ai/i, /diffbot/i,
        /perplexitybot/i, /youbot/i, /ai2bot/i,
        /amazonbot/i, /meta-externalagent/i,
        /google-extended/i, /friendlycrawler/i,
        /timpibot/i, /velenpublicwebcrawler/i,
        /webzio-extended/i, /imagesiftbot/i,

        # ── Social / preview bots ───────────────────────────────────
        /facebookexternalhit/i, /facebot/i,
        /twitterbot/i, /linkedinbot/i,
        /whatsapp/i, /telegrambot/i, /discordbot/i,
        /slackbot/i, /skypeuripreview/i, /embedly/i,
        /pinterestbot/i, /vkshare/i, /redditbot/i,

        # ── SEO / marketing tools ───────────────────────────────────
        /semrushbot/i, /ahrefsbot/i, /dotbot/i, /mj12bot/i,
        /rogerbot/i, /screaming frog/i, /seokicks/i,
        /blexbot/i, /sistrix/i, /serpstatbot/i,
        /megaindex/i, /majestic/i, /dataforseobot/i,
        /mojeekbot/i, /zoominfobot/i, /hubspot/i,

        # ── Monitoring / uptime ─────────────────────────────────────
        /pingdom/i, /uptimerobot/i, /statuscake/i,
        /newrelicpinger/i, /datadog/i, /site24x7/i,
        /hetrixtools/i, /freshping/i,

        # ── Feed readers / aggregators ──────────────────────────────
        /feedfetcher/i, /feedly/i, /newsblur/i, /inoreader/i,
        /theoldreader/i, /feedbin/i, /blogtrottr/i,
        /tiny tiny rss/i, /netnewswire/i,

        # ── Headless browsers / automation ──────────────────────────
        /headlesschrome/i, /phantomjs/i, /selenium/i,
        /puppeteer/i, /playwright/i, /cypress/i,
        /nightmarejs/i, /splash/i, /htmlunit/i,

        # ── HTTP libraries ──────────────────────────────────────────
        /wget/i, /curl/i, /libwww-perl/i,
        /python-requests/i, /python-urllib/i, /aiohttp/i, /scrapy/i, /httpx/i,
        /httpie/i, /axios/i, /node-fetch/i, /undici/i,
        /go-http-client/i, /fasthttp/i,
        /java\//i, /okhttp/i, /apache-httpclient/i,
        /ruby/i, /mechanize/i, /typhoeus/i, /faraday/i,
        /php\//i, /guzzlehttp/i,
        /dart:io/i, /http\.rb/i, /reqwest/i,

        # ── Other known bots ────────────────────────────────────────
        /mediapartners/i, /adsbot/i, /apis-google/i,
        /archive\.org_bot/i, /internetarchive/i,
        /coccoc/i, /mail\.ru/i, /qwantify/i,
        /naver/i, /daumoa/i, /purebot/i,
        /buck/i, /newspaper/i, /netcraft/i, /zgrab/i
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
