# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Services::ServerTracker do
  let!(:property) { create(:property) }

  describe ".track_pageview" do
    it "enqueues a ProcessTrackingJob with pageview payload" do
      expect {
        described_class.track_pageview(
          property_key: property.key,
          url: "https://example.com/page",
          path: "/page",
          title: "Page Title",
          visitor_id: "v123",
          ip: "192.168.1.1",
          user_agent: "Mozilla/5.0"
        )
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob).with(hash_including(
        "type" => "pageview",
        "property_key" => property.key,
        "url" => "https://example.com/page",
        "path" => "/page",
        "title" => "Page Title",
        "visitor_id" => "v123"
      ))
    end

    it "anonymizes IP when configured" do
      LocalAnalytics.configuration.ip_anonymization = true
      expect {
        described_class.track_pageview(
          property_key: property.key, url: "https://example.com", path: "/",
          ip: "192.168.1.100"
        )
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob).with(hash_including(
        "ip" => "192.168.1.0"
      ))
    end

    it "generates a visitor_id from IP + UA when none provided" do
      expect {
        described_class.track_pageview(
          property_key: property.key, url: "https://example.com", path: "/",
          ip: "1.2.3.4", user_agent: "Test"
        )
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob).with(
        hash_including("visitor_id" => be_a(String))
      )
    end
  end

  describe ".track_event" do
    it "enqueues a ProcessTrackingJob with event payload" do
      expect {
        described_class.track_event(
          property_key: property.key,
          category: "purchase",
          action: "completed",
          name: "Premium",
          value: 99.0,
          visitor_id: "v123"
        )
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob).with(hash_including(
        "type" => "event",
        "category" => "purchase",
        "action" => "completed",
        "name" => "Premium",
        "value" => 99.0
      ))
    end
  end

  describe ".track_conversion" do
    it "enqueues a ProcessTrackingJob with conversion payload" do
      expect {
        described_class.track_conversion(
          property_key: property.key,
          goal_key: "signup",
          visitor_id: "v123",
          revenue: 49.0
        )
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob).with(hash_including(
        "type" => "conversion",
        "goal_key" => "signup",
        "revenue" => 49.0
      ))
    end
  end
end
