# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::DashboardReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  let!(:visit1) do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 10.minutes, bounced: false)
  end
  let!(:visit2) do
    create(:visit, property: property, visitor: visitor,
           started_at: 2.days.ago, ended_at: 2.days.ago + 2.minutes, bounced: true)
  end

  before do
    create(:pageview, property: property, visit: visit1, visitor: visitor, viewed_at: 3.days.ago)
    create(:pageview, property: property, visit: visit1, visitor: visitor, viewed_at: 3.days.ago + 5.minutes, path: "/about", url: "https://example.com/about")
    create(:pageview, property: property, visit: visit2, visitor: visitor, viewed_at: 2.days.ago)
    create(:conversion, property: property, visit: visit1, visitor: visitor,
           goal: create(:goal, property: property), revenue: 25.0, converted_at: 3.days.ago)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#total_pageviews" do
    it "counts all pageviews in range" do
      expect(report.total_pageviews).to eq(3)
    end
  end

  describe "#total_visits" do
    it "counts visits in range" do
      expect(report.total_visits).to eq(2)
    end
  end

  describe "#total_unique_visitors" do
    it "counts distinct visitors" do
      expect(report.total_unique_visitors).to eq(1)
    end
  end

  describe "#bounce_rate" do
    it "calculates bounce rate" do
      expect(report.bounce_rate).to eq(50.0)
    end

    it "returns 0 with no visits" do
      r = described_class.new(property: create(:property, name: "Empty"), date_range: date_range)
      expect(r.bounce_rate).to eq(0.0)
    end
  end

  describe "#avg_visit_duration" do
    it "returns average duration in seconds" do
      expect(report.avg_visit_duration).to be > 0
    end
  end

  describe "#avg_pages_per_visit" do
    it "calculates pages per visit" do
      expect(report.avg_pages_per_visit).to eq(1.5)
    end
  end

  describe "#total_conversions" do
    it "counts conversions" do
      expect(report.total_conversions).to eq(1)
    end
  end

  describe "#total_revenue" do
    it "sums revenue" do
      expect(report.total_revenue).to eq(25.0)
    end
  end

  describe "#daily_stats" do
    it "returns an array of daily hashes" do
      stats = report.daily_stats
      expect(stats).to be_an(Array)
      expect(stats.length).to eq(date_range.to_a.length)
      expect(stats.first).to have_key(:date)
      expect(stats.first).to have_key(:visits)
      expect(stats.first).to have_key(:pageviews)
      expect(stats.first).to have_key(:visitors)
    end

    it "has correct totals across days" do
      total = report.daily_stats.sum { |d| d[:pageviews] }
      expect(total).to eq(3)
    end
  end

  describe "#top_pages" do
    it "returns pages ordered by views" do
      pages = report.top_pages
      expect(pages.first.path).to eq("/test")
      expect(pages.first.total.to_i).to eq(2)
    end
  end

  describe "#top_referrers" do
    before { visit1.update!(referrer_host: "google.com") }

    it "returns referrers with counts" do
      refs = report.top_referrers
      expect(refs).to include(["google.com", 1])
    end
  end

  describe "#to_csv" do
    it "generates CSV output" do
      csv = report.to_csv
      expect(csv).to include("date,visits,pageviews,visitors")
    end
  end
end
