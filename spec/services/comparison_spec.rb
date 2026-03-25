# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Comparison period support" do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }

  # Current period: last 7 days
  let(:current_range) { 7.days.ago.to_date..Date.current }

  # Previous period: 7 days before that
  let(:prev_range) { 14.days.ago.to_date..8.days.ago.to_date }

  before do
    # Create visits in current period
    3.times do |i|
      visit = create(:visit, property: property, visitor: visitor,
                     started_at: (5 - i).days.ago,
                     ended_at: (5 - i).days.ago + 10.minutes)
      create(:pageview, property: property, visit: visit, visitor: visitor,
             path: "/home", viewed_at: (5 - i).days.ago)
    end

    # Create visits in previous period
    visit_prev = create(:visit, property: property, visitor: visitor,
                        started_at: 10.days.ago,
                        ended_at: 10.days.ago + 5.minutes)
    create(:pageview, property: property, visit: visit_prev, visitor: visitor,
           path: "/home", viewed_at: 10.days.ago)
  end

  describe LocalAnalytics::Reports::DashboardReport do
    context "without comparison" do
      let(:report) { described_class.new(property: property, date_range: current_range) }

      it "returns nil for comparison" do
        expect(report.comparison).to be_nil
        expect(report.comparing?).to be false
        expect(report.comparison_daily_stats).to be_nil
      end
    end

    context "with comparison" do
      let(:report) do
        described_class.new(
          property: property,
          date_range: current_range,
          comparison_range: prev_range
        )
      end

      it "is comparing" do
        expect(report.comparing?).to be true
      end

      it "returns comparison metrics" do
        cmp = report.comparison
        expect(cmp).to be_a(Hash)
        expect(cmp[:visits]).to eq(1)
        expect(cmp[:pageviews]).to eq(1)
        expect(cmp).to have_key(:visitors_delta)
        expect(cmp).to have_key(:visits_delta)
        expect(cmp).to have_key(:pageviews_delta)
        expect(cmp).to have_key(:bounce_rate_delta)
      end

      it "computes positive delta when current > previous" do
        cmp = report.comparison
        # Current has 3 visits, previous has 1 => +200%
        expect(cmp[:visits_delta]).to eq(200.0)
      end

      it "returns comparison_daily_stats" do
        stats = report.comparison_daily_stats
        expect(stats).to be_an(Array)
        expect(stats.length).to eq(prev_range.to_a.length)
        expect(stats.first).to have_key(:visitors)
      end
    end
  end

  describe LocalAnalytics::Reports::PagesReport do
    context "with comparison" do
      let(:report) do
        described_class.new(
          property: property,
          date_range: current_range,
          comparison_range: prev_range,
          report_type: "all"
        )
      end

      it "returns comparison_by_path" do
        by_path = report.comparison_by_path
        expect(by_path).to be_a(Hash)
        expect(by_path["/home"]).to eq(1)
      end
    end

    context "without comparison" do
      let(:report) do
        described_class.new(property: property, date_range: current_range, report_type: "all")
      end

      it "returns empty comparison_by_path" do
        expect(report.comparison_by_path).to eq({})
      end
    end
  end

  describe LocalAnalytics::Reports::ReferrersReport do
    before do
      # Add referrer data to visits
      property.visits.where("started_at > ?", 8.days.ago).update_all(referrer_host: "google.com")
      property.visits.where("started_at < ?", 8.days.ago).update_all(referrer_host: "google.com")
    end

    context "with comparison" do
      let(:report) do
        described_class.new(
          property: property,
          date_range: current_range,
          comparison_range: prev_range
        )
      end

      it "returns comparison_by_host" do
        by_host = report.comparison_by_host
        expect(by_host).to be_a(Hash)
        expect(by_host["google.com"]).to eq(1)
      end
    end
  end

  describe "BaseReport#pct_change" do
    let(:report) { LocalAnalytics::Reports::DashboardReport.new(property: property, date_range: current_range) }

    it "computes positive change" do
      expect(report.send(:pct_change, 150, 100)).to eq(50.0)
    end

    it "computes negative change" do
      expect(report.send(:pct_change, 50, 100)).to eq(-50.0)
    end

    it "returns nil for zero previous" do
      expect(report.send(:pct_change, 100, 0)).to be_nil
    end

    it "returns 0 for equal values" do
      expect(report.send(:pct_change, 100, 100)).to eq(0.0)
    end
  end
end
