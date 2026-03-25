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

  describe "#touch_ended_at!" do
    it "updates ended_at to current time" do
      visit = create(:visit, property: property, visitor: visitor,
                     started_at: 10.minutes.ago, ended_at: 5.minutes.ago)
      visit.touch_ended_at!
      expect(visit.reload.ended_at).to be_within(2.seconds).of(Time.current)
    end

    it "accepts a custom time" do
      visit = create(:visit, property: property, visitor: visitor,
                     started_at: 10.minutes.ago, ended_at: 5.minutes.ago)
      custom = 1.minute.ago
      visit.touch_ended_at!(custom)
      expect(visit.reload.ended_at).to be_within(1.second).of(custom)
    end
  end

  describe "scopes" do
    let!(:bounced_visit) { create(:visit, property: property, visitor: visitor, bounced: true, started_at: 3.days.ago, ended_at: 3.days.ago + 1.minute) }
    let!(:normal_visit) { create(:visit, property: property, visitor: visitor, bounced: false, started_at: 1.day.ago, ended_at: 1.day.ago + 10.minutes) }

    it ".bounced returns bounced visits" do
      expect(described_class.bounced).to contain_exactly(bounced_visit)
    end

    it ".not_bounced returns non-bounced visits" do
      expect(described_class.not_bounced).to contain_exactly(normal_visit)
    end

    it ".in_range filters by started_at" do
      expect(described_class.in_range(2.days.ago, Time.current)).to contain_exactly(normal_visit)
    end

    it ".for_property filters by property" do
      expect(described_class.for_property(property.id).count).to eq(2)
    end
  end

  describe "associations" do
    it "has many pageviews" do
      visit = create(:visit, property: property, visitor: visitor)
      pv = create(:pageview, property: property, visit: visit, visitor: visitor)
      expect(visit.pageviews).to contain_exactly(pv)
    end

    it "has many events" do
      visit = create(:visit, property: property, visitor: visitor)
      event = create(:event, property: property, visit: visit, visitor: visitor)
      expect(visit.events).to contain_exactly(event)
    end
  end
end
