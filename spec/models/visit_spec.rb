# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Visit, type: :model do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }

  describe "#duration" do
    it "returns seconds between start and end" do
      visit = create(:visit, property: property, visitor: visitor,
                     started_at: 5.minutes.ago, ended_at: Time.current)
      expect(visit.duration).to be_within(1).of(300)
    end

    it "returns 0 when ended_at is nil" do
      visit = build(:visit, started_at: Time.current, ended_at: nil)
      expect(visit.duration).to eq(0)
    end
  end

  describe "#update_bounce_status!" do
    it "marks as not bounced when multiple pageviews exist" do
      visit = create(:visit, property: property, visitor: visitor, bounced: true)
      create(:pageview, property: property, visit: visit, visitor: visitor)
      create(:pageview, property: property, visit: visit, visitor: visitor, path: "/other", url: "https://example.com/other")
      visit.update_bounce_status!
      expect(visit.reload.bounced).to be false
    end

    it "marks as bounced with single pageview" do
      visit = create(:visit, property: property, visitor: visitor, bounced: false)
      create(:pageview, property: property, visit: visit, visitor: visitor)
      visit.update_bounce_status!
      expect(visit.reload.bounced).to be true
    end
  end
end
