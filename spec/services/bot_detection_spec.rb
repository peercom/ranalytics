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

    it "allows normal browsers" do
      ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      expect(described_class.bot?(ua)).to be false
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
