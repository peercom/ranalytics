# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Conversion, type: :model do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor) }
  let(:goal) { create(:goal, property: property) }

  describe "validations" do
    it "is valid with valid attributes" do
      conversion = build(:conversion, property: property, visit: visit, visitor: visitor, goal: goal)
      expect(conversion).to be_valid
    end

    it "prevents duplicate goal per visit" do
      create(:conversion, property: property, visit: visit, visitor: visitor, goal: goal)
      dup = build(:conversion, property: property, visit: visit, visitor: visitor, goal: goal)
      expect(dup).not_to be_valid
      expect(dup.errors[:goal_id]).to include("already converted in this visit")
    end

    it "allows same goal in different visits" do
      create(:conversion, property: property, visit: visit, visitor: visitor, goal: goal)
      visit2 = create(:visit, property: property, visitor: visitor)
      conversion = build(:conversion, property: property, visit: visit2, visitor: visitor, goal: goal)
      expect(conversion).to be_valid
    end
  end

  describe "defaults" do
    it "sets converted_at on validation" do
      conversion = build(:conversion, property: property, visit: visit, visitor: visitor, goal: goal, converted_at: nil)
      conversion.valid?
      expect(conversion.converted_at).to be_present
    end
  end

  describe "scopes" do
    let!(:old_conversion) { create(:conversion, property: property, visit: visit, visitor: visitor, goal: goal, converted_at: 10.days.ago) }

    it ".in_range filters by converted_at" do
      expect(described_class.in_range(5.days.ago, Time.current)).to be_empty
      expect(described_class.in_range(15.days.ago, Time.current)).to contain_exactly(old_conversion)
    end

    it ".for_goal filters by goal" do
      expect(described_class.for_goal(goal.id)).to contain_exactly(old_conversion)
    end
  end
end
