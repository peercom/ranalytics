# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Services::Aggregator do
  let(:property) { create(:property) }
  let(:date) { Date.yesterday }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) do
    create(:visit, property: property, visitor: visitor,
           started_at: date.beginning_of_day + 1.hour,
           ended_at: date.beginning_of_day + 2.hours,
           bounced: false,
           browser: "Chrome", os: "macOS", device_type: "desktop",
           referrer_host: "google.com", referrer_source: "google", referrer_medium: "search",
           country: "US", region: "CA", city: "San Francisco")
  end

  before do
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/home", viewed_at: date.beginning_of_day + 1.hour)
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/about", viewed_at: date.beginning_of_day + 1.hour + 30.minutes)
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "click", action: "cta", value: 5.0, created_at: date.beginning_of_day + 1.hour)
  end

  describe "#aggregate_all" do
    it "creates page aggregates" do
      expect { described_class.new(property: property, date: date).aggregate_all }
        .to change(LocalAnalytics::DailyPageAggregate, :count).by(2)
    end

    it "creates referrer aggregates" do
      described_class.new(property: property, date: date).aggregate_all
      expect(LocalAnalytics::DailyReferrerAggregate.count).to be >= 1

      agg = LocalAnalytics::DailyReferrerAggregate.find_by(referrer_host: "google.com")
      expect(agg.visits_count).to eq(1)
    end

    it "creates device aggregates" do
      described_class.new(property: property, date: date).aggregate_all
      expect(LocalAnalytics::DailyDeviceAggregate.count).to be >= 1
    end

    it "creates location aggregates" do
      described_class.new(property: property, date: date).aggregate_all
      agg = LocalAnalytics::DailyLocationAggregate.find_by(country: "US")
      expect(agg).to be_present
    end

    it "creates event aggregates" do
      described_class.new(property: property, date: date).aggregate_all
      agg = LocalAnalytics::DailyEventAggregate.find_by(category: "click", action: "cta")
      expect(agg.events_count).to eq(1)
      expect(agg.total_value).to eq(5.0)
    end

    it "is idempotent" do
      2.times { described_class.new(property: property, date: date).aggregate_all }
      expect(LocalAnalytics::DailyPageAggregate.count).to eq(2)
    end
  end
end
