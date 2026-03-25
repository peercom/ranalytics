# frozen_string_literal: true

require "spec_helper"
require "local_analytics/importers/active_analytics"

RSpec.describe LocalAnalytics::Importers::ActiveAnalytics do
  let(:property) { create(:property, name: "example.com") }

  before do
    conn = ActiveRecord::Base.connection

    # Create active_analytics tables for testing
    unless conn.table_exists?("active_analytics_views_per_days")
      conn.create_table :active_analytics_views_per_days do |t|
        t.string :site, null: false
        t.string :page, null: false
        t.date :date, null: false
        t.bigint :total, default: 1
        t.string :referrer_host
        t.string :referrer_path
        t.timestamps
      end
    end

    unless conn.table_exists?("active_analytics_browsers_per_days")
      conn.create_table :active_analytics_browsers_per_days do |t|
        t.string :site, null: false
        t.string :name, null: false
        t.string :version, null: false
        t.date :date, null: false
        t.bigint :total, default: 1
        t.timestamps
      end
    end

    # Seed test data
    now = Time.current
    conn.execute(<<~SQL)
      INSERT INTO active_analytics_views_per_days (site, page, date, total, referrer_host, referrer_path, created_at, updated_at)
      VALUES
        ('example.com', '/', '#{3.days.ago.to_date}', 100, NULL, NULL, '#{now}', '#{now}'),
        ('example.com', '/about', '#{3.days.ago.to_date}', 50, 'google.com', '/search', '#{now}', '#{now}'),
        ('example.com', '/', '#{2.days.ago.to_date}', 80, NULL, NULL, '#{now}', '#{now}'),
        ('example.com', '/pricing', '#{2.days.ago.to_date}', 30, 'twitter.com', '/status/123', '#{now}', '#{now}')
    SQL

    conn.execute(<<~SQL)
      INSERT INTO active_analytics_browsers_per_days (site, name, version, date, total, created_at, updated_at)
      VALUES
        ('example.com', 'Chrome', '120', '#{3.days.ago.to_date}', 80, '#{now}', '#{now}'),
        ('example.com', 'Safari', '17', '#{3.days.ago.to_date}', 70, '#{now}', '#{now}'),
        ('example.com', 'Chrome', '120', '#{2.days.ago.to_date}', 60, '#{now}', '#{now}')
    SQL
  end

  after do
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM active_analytics_views_per_days")
    conn.execute("DELETE FROM active_analytics_browsers_per_days")
  end

  describe ".import!" do
    context "with target property" do
      it "imports page aggregates" do
        expect {
          described_class.import!(site: "example.com", property: property)
        }.to change(LocalAnalytics::DailyPageAggregate, :count).by(4)
      end

      it "imports referrer aggregates" do
        described_class.import!(site: "example.com", property: property)
        referrers = LocalAnalytics::DailyReferrerAggregate.where(property: property)
        expect(referrers.count).to eq(2)
        google = referrers.find_by(referrer_host: "google.com")
        expect(google.referrer_medium).to eq("search")
        twitter = referrers.find_by(referrer_host: "twitter.com")
        expect(twitter.referrer_medium).to eq("social")
      end

      it "imports device aggregates" do
        described_class.import!(site: "example.com", property: property)
        devices = LocalAnalytics::DailyDeviceAggregate.where(property: property)
        expect(devices.count).to eq(3)
        chrome = devices.where(browser: "Chrome")
        expect(chrome.sum(:visits_count)).to eq(140)
      end

      it "creates synthetic visits" do
        described_class.import!(site: "example.com", property: property)
        expect(property.visits.count).to eq(2) # one per day
      end

      it "creates a synthetic visitor" do
        described_class.import!(site: "example.com", property: property)
        expect(property.visitors.count).to eq(1)
        expect(property.visitors.first.visitor_token).to start_with("__imported_")
      end

      it "sets pageview counts correctly" do
        described_class.import!(site: "example.com", property: property)
        day1 = LocalAnalytics::DailyPageAggregate.where(property: property, date: 3.days.ago.to_date)
        expect(day1.sum(:pageviews_count)).to eq(150) # 100 + 50
      end

      it "estimates unique visitors" do
        described_class.import!(site: "example.com", property: property)
        agg = LocalAnalytics::DailyPageAggregate.find_by(property: property, path: "/", date: 3.days.ago.to_date)
        expect(agg.unique_visitors).to eq(60) # 100 * 0.6 = 60
      end

      it "is idempotent (re-running updates instead of duplicating)" do
        2.times { described_class.import!(site: "example.com", property: property) }
        expect(LocalAnalytics::DailyPageAggregate.where(property: property).count).to eq(4)
      end
    end

    context "auto-creating properties" do
      it "creates a property when none exists" do
        LocalAnalytics::Property.destroy_all
        expect {
          described_class.import!(site: "example.com")
        }.to change(LocalAnalytics::Property, :count).by(1)
        expect(LocalAnalytics::Property.last.name).to eq("example.com")
      end

      it "reuses existing property with matching name" do
        property # ensure it exists
        expect {
          described_class.import!(site: "example.com")
        }.not_to change(LocalAnalytics::Property, :count)
      end
    end

    context "dry run" do
      it "does not create any records" do
        expect {
          described_class.import!(site: "example.com", dry_run: true)
        }.not_to change(LocalAnalytics::DailyPageAggregate, :count)
      end

      it "returns stats with zeroes" do
        stats = described_class.import!(site: "example.com", dry_run: true)
        expect(stats[:pages]).to eq(0)
      end
    end

    context "referrer classification" do
      it "classifies google as search" do
        described_class.import!(site: "example.com", property: property)
        agg = LocalAnalytics::DailyReferrerAggregate.find_by(referrer_host: "google.com")
        expect(agg.referrer_medium).to eq("search")
      end

      it "classifies twitter as social" do
        described_class.import!(site: "example.com", property: property)
        agg = LocalAnalytics::DailyReferrerAggregate.find_by(referrer_host: "twitter.com")
        expect(agg.referrer_medium).to eq("social")
      end
    end
  end
end
