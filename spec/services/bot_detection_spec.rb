# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::BotDetection::Detector do
  describe ".bot?" do
    it "detects Googlebot" do
      expect(described_class.bot?("Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)")).to be true
    end

    it "detects curl" do
      expect(described_class.bot?("curl/7.68.0")).to be true
    end

    it "detects empty user agent" do
      expect(described_class.bot?("")).to be true
      expect(described_class.bot?(nil)).to be true
    end

    it "detects AI crawlers" do
      expect(described_class.bot?("Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.0; +https://openai.com/gptbot)")).to be true
      expect(described_class.bot?("ClaudeBot/1.0")).to be true
      expect(described_class.bot?("Mozilla/5.0 (compatible; Bytespider; spider-feedback@bytedance.com)")).to be true
      expect(described_class.bot?("CCBot/2.0 (https://commoncrawl.org/faq/)")).to be true
      expect(described_class.bot?("PerplexityBot/1.0")).to be true
      expect(described_class.bot?("Amazonbot/0.1")).to be true
      expect(described_class.bot?("Meta-ExternalAgent/1.0")).to be true
      expect(described_class.bot?("cohere-ai")).to be true
    end

    it "detects SEO tools" do
      expect(described_class.bot?("Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)")).to be true
      expect(described_class.bot?("Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)")).to be true
      expect(described_class.bot?("Screaming Frog SEO Spider/19.0")).to be true
      expect(described_class.bot?("DataForSeoBot/1.0")).to be true
    end

    it "detects social preview bots" do
      expect(described_class.bot?("facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)")).to be true
      expect(described_class.bot?("Slackbot-LinkExpanding 1.0")).to be true
      expect(described_class.bot?("Discordbot/2.0")).to be true
      expect(described_class.bot?("redditbot/1.0")).to be true
    end

    it "detects HTTP libraries" do
      expect(described_class.bot?("python-requests/2.28.0")).to be true
      expect(described_class.bot?("axios/1.4.0")).to be true
      expect(described_class.bot?("Go-http-client/2.0")).to be true
      expect(described_class.bot?("GuzzleHttp/7.0")).to be true
      expect(described_class.bot?("Faraday v2.7.0")).to be true
      expect(described_class.bot?("Scrapy/2.9.0")).to be true
    end

    it "detects headless/automation tools" do
      expect(described_class.bot?("Mozilla/5.0 HeadlessChrome/120.0.0.0")).to be true
      expect(described_class.bot?("Playwright/1.40.0")).to be true
    end

    it "detects feed readers" do
      expect(described_class.bot?("Feedly/1.0")).to be true
      expect(described_class.bot?("FeedFetcher-Google")).to be true
      expect(described_class.bot?("NewsBlur Feed Fetcher")).to be true
    end

    it "detects monitoring services" do
      expect(described_class.bot?("Pingdom.com_bot_version_1.4")).to be true
      expect(described_class.bot?("StatusCake")).to be true
      expect(described_class.bot?("Datadog Agent/7.0")).to be true
    end

    it "allows normal desktop browsers" do
      expect(described_class.bot?("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")).to be false
      expect(described_class.bot?("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0")).to be false
      expect(described_class.bot?("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15")).to be false
    end

    it "allows normal mobile browsers" do
      expect(described_class.bot?("Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1")).to be false
      expect(described_class.bot?("Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")).to be false
    end

    it "respects ignored IPs" do
      LocalAnalytics.configuration.bot_ignore_ips = ["10.0.0.1"]
      expect(described_class.bot?("Mozilla/5.0 Chrome", "10.0.0.1")).to be true
      LocalAnalytics.configuration.bot_ignore_ips = []
    end

    it "respects ignored CIDRs" do
      LocalAnalytics.configuration.bot_ignore_cidrs = ["10.0.0.0/8"]
      expect(described_class.bot?("Mozilla/5.0 Chrome", "10.0.0.50")).to be true
      LocalAnalytics.configuration.bot_ignore_cidrs = []
    end
  end
end
