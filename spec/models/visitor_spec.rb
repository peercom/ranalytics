# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Visitor, type: :model do
  let(:property) { create(:property) }

  describe "validations" do
    it "is valid with valid attributes" do
      visitor = build(:visitor, property: property)
      expect(visitor).to be_valid
    end

    it "requires a visitor_token" do
      visitor = build(:visitor, property: property, visitor_token: nil)
      expect(visitor).not_to be_valid
    end

    it "enforces unique visitor_token per property" do
      create(:visitor, property: property, visitor_token: "abc")
      dup = build(:visitor, property: property, visitor_token: "abc")
      expect(dup).not_to be_valid
    end

    it "allows same token across different properties" do
      other = create(:property, name: "Other")
      create(:visitor, property: property, visitor_token: "abc")
      visitor = build(:visitor, property: other, visitor_token: "abc")
      expect(visitor).to be_valid
    end
  end

  describe "scopes" do
    let!(:returning_visitor) { create(:visitor, property: property, returning: true) }
    let!(:new_visitor) { create(:visitor, property: property, returning: false) }

    it ".returning returns returning visitors" do
      expect(described_class.returning).to contain_exactly(returning_visitor)
    end

    it ".new_visitors returns non-returning visitors" do
      expect(described_class.new_visitors).to contain_exactly(new_visitor)
    end
  end

  describe "#mark_returning!" do
    it "sets returning to true" do
      visitor = create(:visitor, property: property, returning: false)
      visitor.mark_returning!
      expect(visitor.reload.returning).to be true
    end

    it "is a no-op if already returning" do
      visitor = create(:visitor, property: property, returning: true)
      expect { visitor.mark_returning! }.not_to change { visitor.reload.updated_at }
    end
  end

  describe "associations" do
    let(:visitor) { create(:visitor, property: property) }
    let(:visit) { create(:visit, property: property, visitor: visitor) }

    it "has many visits" do
      visit # create
      expect(visitor.visits).to contain_exactly(visit)
    end

    it "destroys visits on destroy" do
      visit # create
      expect { visitor.destroy }.to change(LocalAnalytics::Visit, :count).by(-1)
    end
  end
end
