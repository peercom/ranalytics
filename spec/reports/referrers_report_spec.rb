# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::ReferrersReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes,
           referrer_host: "google.com", referrer_source: "google", referrer_medium: "search", bounced: false)
    create(:visit, property: property, visitor: visitor,
           started_at: 2.days.ago, ended_at: 2.days.ago + 2.minutes,
           referrer_host: "twitter.com", referrer_source: "twitter", referrer_medium: "social", bounced: true)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#rows" do
    it "returns referrers grouped by host" do
      hosts = report.rows.map(&:referrer_host)
      expect(hosts).to contain_exactly("google.com", "twitter.com")
    end

    it "includes visit counts" do
      google = report.rows.find { |r| r.referrer_host == "google.com" }
      expect(google.visits.to_i).to eq(1)
    end
  end

  describe "#by_medium" do
    it "returns visits grouped by medium" do
      mediums = report.by_medium.to_h
      expect(mediums["search"]).to eq(1)
      expect(mediums["social"]).to eq(1)
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("referrer_host")
      expect(csv).to include("google.com")
    end
  end

  describe "#comparison_by_host" do
    it "returns empty hash when not comparing" do
      expect(report.comparison_by_host).to eq({})
    end

    it "returns previous-period counts when comparing" do
      prev_range = 14.days.ago.to_date..8.days.ago.to_date
      create(:visit, property: property, visitor: visitor,
             started_at: 10.days.ago, ended_at: 10.days.ago + 5.minutes,
             referrer_host: "google.com")

      r = described_class.new(property: property, date_range: date_range, comparison_range: prev_range)
      expect(r.comparison_by_host["google.com"]).to eq(1)
    end
  end
end
