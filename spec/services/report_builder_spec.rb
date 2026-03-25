# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Services::ReportBuilder do
  let(:property) { create(:property, name: "My Site") }

  describe "#build" do
    LocalAnalytics::ReportSubscription::REPORT_TYPES.each do |report_type|
      it "builds a #{report_type} report" do
        sub = build(:report_subscription, property: property, report_type: report_type, frequency: "daily")
        builder = described_class.new(sub)
        report = builder.build
        expect(report).to respond_to(:to_csv)
        expect(report.property).to eq(property)
      end
    end

    it "raises for unknown report type" do
      sub = build(:report_subscription, property: property)
      allow(sub).to receive(:report_type).and_return("nonexistent")
      builder = described_class.new(sub)
      expect { builder.build }.to raise_error(ArgumentError, /Unknown report type/)
    end
  end

  describe "#report_title" do
    it "returns a formatted title" do
      sub = build(:report_subscription, property: property, report_type: "dashboard")
      title = described_class.new(sub).report_title
      expect(title).to eq("My Site — Dashboard Report")
    end
  end

  describe "#period_label" do
    it "returns the date range as a string" do
      sub = build(:report_subscription, property: property, frequency: "daily")
      label = described_class.new(sub).period_label
      expect(label).to include(Date.yesterday.to_s)
    end
  end
end
