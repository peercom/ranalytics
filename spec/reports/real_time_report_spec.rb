# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::RealTimeReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }

  let!(:recent_visit) do
    create(:visit, property: property, visitor: visitor,
           started_at: 2.minutes.ago, ended_at: 1.minute.ago,
           referrer_host: "google.com", utm_campaign: "spring")
  end
  let!(:old_visit) do
    create(:visit, property: property, visitor: visitor,
           started_at: 2.hours.ago, ended_at: 2.hours.ago + 5.minutes)
  end

  before do
    create(:pageview, property: property, visit: recent_visit, visitor: visitor,
           path: "/home", viewed_at: 2.minutes.ago)
    create(:pageview, property: property, visit: old_visit, visitor: visitor,
           path: "/old", viewed_at: 2.hours.ago)
    create(:event, property: property, visit: recent_visit, visitor: visitor,
           category: "click", action: "cta", created_at: 2.minutes.ago)
  end

  subject(:report) { described_class.new(property: property) }

  describe "#active_visitors_5min" do
    it "counts visitors with recent pageviews" do
      expect(report.active_visitors_5min).to eq(1)
    end
  end

  describe "#active_visitors_30min" do
    it "counts visitors in last 30 minutes" do
      expect(report.active_visitors_30min).to eq(1)
    end
  end

  describe "#top_pages" do
    it "returns recent top pages" do
      pages = report.top_pages
      expect(pages.map(&:first)).to include("/home")
      expect(pages.map(&:first)).not_to include("/old")
    end
  end

  describe "#top_referrers" do
    it "returns recent referrers" do
      refs = report.top_referrers
      expect(refs).to include(["google.com", 1])
    end
  end

  describe "#top_campaigns" do
    it "returns recent campaigns" do
      campaigns = report.top_campaigns
      expect(campaigns).to include(["spring", 1])
    end
  end

  describe "#recent_events" do
    it "returns recent events" do
      events = report.recent_events
      expect(events.length).to eq(1)
      expect(events.first.category).to eq("click")
    end
  end

  describe "#recent_pageviews" do
    it "returns recent pageviews ordered by time" do
      pvs = report.recent_pageviews
      expect(pvs.first.path).to eq("/home")
    end
  end
end
