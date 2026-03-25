# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Pageview, type: :model do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor) }

  describe "validations" do
    it "is valid with valid attributes" do
      pv = build(:pageview, property: property, visit: visit, visitor: visitor)
      expect(pv).to be_valid
    end

    it "requires url" do
      pv = build(:pageview, property: property, visit: visit, visitor: visitor, url: nil)
      expect(pv).not_to be_valid
    end

    it "requires path" do
      pv = build(:pageview, property: property, visit: visit, visitor: visitor, path: nil)
      expect(pv).not_to be_valid
    end
  end

  describe "defaults" do
    it "sets viewed_at on validation" do
      pv = build(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: nil)
      pv.valid?
      expect(pv.viewed_at).to be_present
    end

    it "does not override explicit viewed_at" do
      time = 1.hour.ago
      pv = build(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: time)
      pv.valid?
      expect(pv.viewed_at).to be_within(1.second).of(time)
    end
  end

  describe "scopes" do
    let!(:old_pv) { create(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: 10.days.ago) }
    let!(:new_pv) { create(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: 1.day.ago, path: "/new", url: "https://example.com/new") }

    it ".in_range filters by viewed_at" do
      expect(described_class.in_range(5.days.ago, Time.current)).to contain_exactly(new_pv)
    end

    it ".for_property filters by property" do
      other = create(:property, name: "Other")
      expect(described_class.for_property(other.id)).to be_empty
      expect(described_class.for_property(property.id).count).to eq(2)
    end
  end

  describe "#entry_page? and #exit_page?" do
    let!(:first_pv) { create(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: 10.minutes.ago, path: "/first", url: "https://example.com/first") }
    let!(:last_pv) { create(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: 1.minute.ago, path: "/last", url: "https://example.com/last") }

    it "identifies the entry page" do
      expect(first_pv.entry_page?).to be true
      expect(last_pv.entry_page?).to be false
    end

    it "identifies the exit page" do
      expect(last_pv.exit_page?).to be true
      expect(first_pv.exit_page?).to be false
    end
  end
end
