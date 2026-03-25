# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::ReportSubscription, type: :model do
  let(:property) { create(:property) }

  describe "validations" do
    it "is valid with valid attributes" do
      sub = build(:report_subscription, property: property)
      expect(sub).to be_valid
    end

    it "requires name" do
      sub = build(:report_subscription, property: property, name: nil)
      expect(sub).not_to be_valid
    end

    it "requires recipients" do
      sub = build(:report_subscription, property: property, recipients: nil)
      expect(sub).not_to be_valid
    end

    it "requires valid frequency" do
      sub = build(:report_subscription, property: property, frequency: "biweekly")
      expect(sub).not_to be_valid
    end

    it "requires valid report_type" do
      sub = build(:report_subscription, property: property, report_type: "invalid")
      expect(sub).not_to be_valid
    end

    it "requires day_of_week for weekly" do
      sub = build(:report_subscription, property: property, frequency: "weekly", day_of_week: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:day_of_week]).to be_present
    end

    it "requires day_of_month for monthly" do
      sub = build(:report_subscription, property: property, frequency: "monthly", day_of_week: nil, day_of_month: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:day_of_month]).to be_present
    end

    it "does not require day_of_week for daily" do
      sub = build(:report_subscription, property: property, frequency: "daily", day_of_week: nil)
      expect(sub).to be_valid
    end
  end

  describe "#recipient_list" do
    it "parses comma-separated recipients" do
      sub = build(:report_subscription, recipients: "a@b.com, c@d.com, e@f.com")
      expect(sub.recipient_list).to eq(["a@b.com", "c@d.com", "e@f.com"])
    end

    it "handles single recipient" do
      sub = build(:report_subscription, recipients: "solo@test.com")
      expect(sub.recipient_list).to eq(["solo@test.com"])
    end

    it "strips whitespace and blanks" do
      sub = build(:report_subscription, recipients: " a@b.com ,  , c@d.com ")
      expect(sub.recipient_list).to eq(["a@b.com", "c@d.com"])
    end
  end

  describe "#report_date_range" do
    it "returns yesterday for daily" do
      sub = build(:report_subscription, frequency: "daily")
      range = sub.report_date_range
      expect(range.first).to eq(Date.yesterday)
      expect(range.last).to eq(Date.yesterday)
    end

    it "returns last 7 days for weekly" do
      sub = build(:report_subscription, frequency: "weekly")
      range = sub.report_date_range
      expect(range.last).to eq(Date.yesterday)
      expect((range.last - range.first).to_i).to eq(6)
    end

    it "returns month-to-yesterday for monthly" do
      sub = build(:report_subscription, frequency: "monthly")
      range = sub.report_date_range
      expect(range.first).to eq(Date.yesterday.beginning_of_month)
      expect(range.last).to eq(Date.yesterday)
    end
  end

  describe "scheduling" do
    it "computes next_send_at on create" do
      sub = create(:report_subscription, property: property)
      expect(sub.next_send_at).to be_present
      expect(sub.next_send_at).to be > Time.current
    end

    it "#advance_schedule! sets last_sent_at and moves next_send_at to future" do
      sub = create(:report_subscription, property: property, next_send_at: 2.weeks.ago)
      sub.advance_schedule!
      expect(sub.last_sent_at).to be_within(2.seconds).of(Time.current)
      expect(sub.next_send_at).to be > Time.current
    end
  end

  describe "scopes" do
    let!(:due_sub) do
      s = create(:report_subscription, property: property, active: true)
      s.update_column(:next_send_at, 1.hour.ago)
      s
    end
    let!(:future_sub) { create(:report_subscription, property: property, active: true) }
    let!(:paused_sub) do
      s = create(:report_subscription, property: property, active: false)
      s.update_column(:next_send_at, 1.hour.ago)
      s
    end

    it ".due returns active subscriptions past their send time" do
      expect(described_class.due).to contain_exactly(due_sub)
    end

    it ".active returns only active subscriptions" do
      expect(described_class.active).to contain_exactly(due_sub, future_sub)
    end
  end
end
