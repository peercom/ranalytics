# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::EventsReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor, started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "video", action: "play", value: 1.0, created_at: 3.days.ago)
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "video", action: "play", value: 1.0, created_at: 3.days.ago + 1.minute)
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "click", action: "cta", created_at: 3.days.ago)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#rows" do
    it "groups by category and action" do
      expect(report.rows.length).to eq(2)
      video = report.rows.find { |r| r.category == "video" }
      expect(video.total_events.to_i).to eq(2)
      expect(video.total_value.to_f).to eq(2.0)
    end
  end

  describe "#categories" do
    it "returns distinct categories" do
      expect(report.categories).to contain_exactly("click", "video")
    end
  end

  describe "category filter" do
    it "filters by category" do
      filtered = described_class.new(property: property, date_range: date_range, category_filter: "video")
      expect(filtered.rows.length).to eq(1)
      expect(filtered.rows.first.category).to eq("video")
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("category,action,events,visitors,total_value")
    end
  end
end
