# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Goal, type: :model do
  let(:property) { create(:property) }

  describe "validations" do
    it "is valid with valid attributes" do
      goal = build(:goal, property: property)
      expect(goal).to be_valid
    end

    it "requires a name" do
      goal = build(:goal, property: property, name: nil)
      expect(goal).not_to be_valid
    end

    it "requires a valid goal_type" do
      goal = build(:goal, property: property, goal_type: "invalid")
      expect(goal).not_to be_valid
    end

    it "enforces unique key per property" do
      create(:goal, property: property, key: "signup")
      dup = build(:goal, property: property, key: "signup")
      expect(dup).not_to be_valid
    end
  end

  describe "#matches_pageview?" do
    let(:goal) do
      create(:goal, property: property, goal_type: "url_match",
             match_config: { "pattern" => "/thank-you", "match_type" => "exact" })
    end
    let(:visitor) { create(:visitor, property: property) }
    let(:visit) { create(:visit, property: property, visitor: visitor) }

    it "matches exact URL" do
      pv = build(:pageview, path: "/thank-you", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be true
    end

    it "does not match different URL" do
      pv = build(:pageview, path: "/other", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be false
    end

    it "supports starts_with matching" do
      goal.update!(match_config: { "pattern" => "/checkout*", "match_type" => "starts_with" })
      pv = build(:pageview, path: "/checkout/step2", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be true
    end

    it "supports contains matching" do
      goal.update!(match_config: { "pattern" => "signup", "match_type" => "contains" })
      pv = build(:pageview, path: "/app/signup/complete", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be true
    end
  end

  describe "#matches_event?" do
    let(:goal) do
      create(:goal, property: property, goal_type: "event_match",
             match_config: { "category" => "purchase", "action" => "completed" })
    end

    it "matches matching event" do
      event = build(:event, category: "purchase", action: "completed")
      expect(goal.matches_event?(event)).to be true
    end

    it "does not match non-matching event" do
      event = build(:event, category: "purchase", action: "started")
      expect(goal.matches_event?(event)).to be false
    end
  end

  describe "#matches_visit_duration?" do
    let(:goal) do
      create(:goal, property: property, goal_type: "time_on_site",
             match_config: { "seconds" => 300 })
    end

    it "matches when duration exceeds threshold" do
      expect(goal.matches_visit_duration?(301)).to be true
    end

    it "does not match below threshold" do
      expect(goal.matches_visit_duration?(299)).to be false
    end
  end
end
