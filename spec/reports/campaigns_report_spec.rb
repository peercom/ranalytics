# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Reports::CampaignsReport do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:date_range) { 7.days.ago.to_date..Date.current }

  before do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 5.minutes,
           utm_source: "newsletter", utm_medium: "email", utm_campaign: "spring_sale")
    create(:visit, property: property, visitor: visitor,
           started_at: 2.days.ago, ended_at: 2.days.ago + 2.minutes,
           utm_source: "google", utm_medium: "cpc", utm_campaign: "brand")
    # Visit without campaign — should not appear
    create(:visit, property: property, visitor: visitor,
           started_at: 1.day.ago, ended_at: 1.day.ago + 1.minute)
  end

  subject(:report) { described_class.new(property: property, date_range: date_range) }

  describe "#rows" do
    it "only returns visits with campaigns" do
      expect(report.rows.length).to eq(2)
    end

    it "includes UTM fields" do
      campaigns = report.rows.map(&:utm_campaign)
      expect(campaigns).to contain_exactly("spring_sale", "brand")
    end
  end

  describe "#to_csv" do
    it "generates CSV" do
      csv = report.to_csv
      expect(csv).to include("utm_campaign")
      expect(csv).to include("spring_sale")
    end
  end
end
