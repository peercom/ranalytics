# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Event, type: :model do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor) }

  describe "validations" do
    it "is valid with valid attributes" do
      event = build(:event, property: property, visit: visit, visitor: visitor)
      expect(event).to be_valid
    end

    it "requires category" do
      event = build(:event, property: property, visit: visit, visitor: visitor, category: nil)
      expect(event).not_to be_valid
    end

    it "requires action" do
      event = build(:event, property: property, visit: visit, visitor: visitor, action: nil)
      expect(event).not_to be_valid
    end

    it "allows nil name and value" do
      event = build(:event, property: property, visit: visit, visitor: visitor, name: nil, value: nil)
      expect(event).to be_valid
    end
  end

  describe "scopes" do
    let!(:old_event) { create(:event, property: property, visit: visit, visitor: visitor, created_at: 10.days.ago) }
    let!(:new_event) { create(:event, property: property, visit: visit, visitor: visitor, created_at: 1.day.ago, category: "download") }

    it ".in_range filters by created_at" do
      expect(described_class.in_range(5.days.ago, Time.current)).to contain_exactly(new_event)
    end

    it ".for_property filters by property" do
      expect(described_class.for_property(property.id).count).to eq(2)
    end
  end

  describe "metadata" do
    it "stores JSONB metadata" do
      event = create(:event, property: property, visit: visit, visitor: visitor,
                     metadata: { "plan" => "premium", "price" => 99 })
      event.reload
      expect(event.metadata["plan"]).to eq("premium")
      expect(event.metadata["price"]).to eq(99)
    end

    it "defaults metadata to empty hash" do
      event = create(:event, property: property, visit: visit, visitor: visitor)
      expect(event.metadata).to eq({})
    end
  end
end
