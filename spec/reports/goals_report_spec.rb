# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::GoalsReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor, started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes) }
  let(:goal) { create(:goal, property: property, name: "Signup") }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:conversion, property: property, visit: visit, visitor: visitor,
           goal: goal, revenue: 50.0, converted_at: 3.days.ago)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#rows" do
    it "returns one row per active goal" do
      expect(report.rows.length).to eq(1)
    end

    it "includes conversion count and rate" do
      row = report.rows.first
      expect(row.conversions_count).to eq(1)
      expect(row.conversion_rate).to be > 0
      expect(row.revenue).to eq(50.0)
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("goal_name,conversions,conversion_rate,revenue")
      expect(csv).to include("Signup")
    end
  end
end

RSpec.describe LocalAnalytics::Reports::GoalDetailReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor, started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes) }
  let(:goal) { create(:goal, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:conversion, property: property, visit: visit, visitor: visitor,
           goal: goal, revenue: 25.0, converted_at: 3.days.ago)
  end

  subject(:report) { described_class.new(property: property, goal: goal, date_range: date_range) }

  describe "#total_conversions" do
    it "counts conversions for the goal" do
      expect(report.total_conversions).to eq(1)
    end
  end

  describe "#total_revenue" do
    it "sums revenue for the goal" do
      expect(report.total_revenue).to eq(25.0)
    end
  end

  describe "#daily_conversions" do
    it "returns a hash of date => count" do
      daily = report.daily_conversions
      expect(daily).to be_a(Hash)
      expect(daily.values.sum).to eq(1)
    end
  end

  describe "#conversion_rate" do
    it "calculates rate against total visits" do
      expect(report.conversion_rate).to be > 0
    end
  end
end
