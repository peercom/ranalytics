# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::SiteSearchReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor, started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "site_search", action: "search", name: "rails analytics",
           created_at: 3.days.ago)
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "site_search", action: "search", name: "rails analytics",
           created_at: 3.days.ago + 1.minute)
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "site_search", action: "search", name: "deploy guide",
           created_at: 3.days.ago + 2.minutes)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#rows" do
    it "groups by search term" do
      expect(report.rows.length).to eq(2)
    end

    it "counts searches per term" do
      top = report.rows.first
      expect(top.search_term).to eq("rails analytics")
      expect(top.searches.to_i).to eq(2)
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("search_term,searches,visitors")
    end
  end
end
