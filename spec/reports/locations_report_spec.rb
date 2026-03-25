# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::LocationsReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes,
           country: "US", region: "CA", city: "San Francisco")
    create(:visit, property: property, visitor: visitor,
           started_at: 2.days.ago, ended_at: 2.days.ago + 2.minutes,
           country: "DE", region: "BY", city: "Munich")
    create(:visit, property: property, visitor: visitor,
           started_at: 1.day.ago, ended_at: 1.day.ago + 1.minute,
           country: "US", region: "NY", city: "New York")
  end

  describe "country dimension" do
    subject(:report) { described_class.new(property: property, date_range: date_range, dimension: "country") }

    it "groups by country" do
      us = report.rows.find { |r| r.country == "US" }
      expect(us.visits.to_i).to eq(2)
    end
  end

  describe "city dimension" do
    subject(:report) { described_class.new(property: property, date_range: date_range, dimension: "city") }

    it "groups by city" do
      cities = report.rows.map(&:city)
      expect(cities).to contain_exactly("San Francisco", "Munich", "New York")
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      report = described_class.new(property: property, date_range: date_range, dimension: "country")
      csv = report.to_csv
      expect(csv).to include("country,visits,visitors")
    end
  end
end
