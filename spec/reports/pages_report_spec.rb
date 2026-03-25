# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::PagesReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  let(:visit) do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes, bounced: false)
  end

  before do
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/home", url: "https://example.com/home", viewed_at: 3.days.ago)
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/about", url: "https://example.com/about", viewed_at: 3.days.ago + 2.minutes)
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/home", url: "https://example.com/home", viewed_at: 3.days.ago + 4.minutes)
  end

  describe "all pages report" do
    subject(:report) { described_class.new(property: property, date_range: date_range, report_type: "all") }

    it "returns rows grouped by path" do
      rows = report.rows
      expect(rows.map(&:path)).to include("/home", "/about")
    end

    it "orders by pageviews descending" do
      rows = report.rows
      expect(rows.first.path).to eq("/home")
      expect(rows.first.pageviews.to_i).to eq(2)
    end

    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("path,pageviews,visitors")
      expect(csv).to include("/home")
    end
  end

  describe "pagination" do
    subject(:report) { described_class.new(property: property, date_range: date_range, report_type: "all", page: 1, per_page: 1) }

    it "limits results to per_page" do
      expect(report.rows.length).to eq(1)
    end
  end

  describe "comparison_by_path" do
    let(:prev_range) { 14.days.ago.to_date..8.days.ago.to_date }
    let(:prev_visit) { create(:visit, property: property, visitor: visitor, started_at: 10.days.ago, ended_at: 10.days.ago + 5.minutes) }

    before do
      create(:pageview, property: property, visit: prev_visit, visitor: visitor,
             path: "/home", url: "https://example.com/home", viewed_at: 10.days.ago)
    end

    it "returns previous period counts by path" do
      report = described_class.new(property: property, date_range: date_range, comparison_range: prev_range, report_type: "all")
      expect(report.comparison_by_path["/home"]).to eq(1)
    end

    it "returns empty hash when not comparing" do
      report = described_class.new(property: property, date_range: date_range, report_type: "all")
      expect(report.comparison_by_path).to eq({})
    end
  end
end
