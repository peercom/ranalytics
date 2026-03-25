# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::DevicesReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes,
           device_type: "desktop", browser: "Chrome", os: "macOS")
    create(:visit, property: property, visitor: visitor,
           started_at: 2.days.ago, ended_at: 2.days.ago + 2.minutes,
           device_type: "mobile", browser: "Safari", os: "iOS")
    create(:visit, property: property, visitor: visitor,
           started_at: 1.day.ago, ended_at: 1.day.ago + 1.minute,
           device_type: "desktop", browser: "Chrome", os: "macOS")
  end

  describe "device_type dimension" do
    subject(:report) { described_class.new(property: property, date_range: date_range, dimension: "device_type") }

    it "groups by device type" do
      desktop = report.rows.find { |r| r.device_type == "desktop" }
      expect(desktop.visits.to_i).to eq(2)
    end
  end

  describe "browser dimension" do
    subject(:report) { described_class.new(property: property, date_range: date_range, dimension: "browser") }

    it "groups by browser" do
      browsers = report.rows.map(&:browser)
      expect(browsers).to contain_exactly("Chrome", "Safari")
    end
  end

  describe "os dimension" do
    subject(:report) { described_class.new(property: property, date_range: date_range, dimension: "os") }

    it "groups by OS" do
      oses = report.rows.map(&:os)
      expect(oses).to contain_exactly("macOS", "iOS")
    end
  end

  describe "invalid dimension" do
    it "falls back to device_type" do
      report = described_class.new(property: property, date_range: date_range, dimension: "evil_sql")
      expect { report.rows }.not_to raise_error
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      report = described_class.new(property: property, date_range: date_range, dimension: "device_type")
      csv = report.to_csv
      expect(csv).to include("device_type,visits,visitors")
    end
  end
end
