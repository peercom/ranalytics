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

    it "matches exactly at threshold" do
      expect(goal.matches_visit_duration?(300)).to be true
    end
  end

  describe "#matches_pages_per_visit?" do
    let(:goal) do
      create(:goal, property: property, goal_type: "pages_per_visit",
             match_config: { "count" => 5 })
    end

    it "matches when count exceeds threshold" do
      expect(goal.matches_pages_per_visit?(6)).to be true
    end

    it "matches at exact threshold" do
      expect(goal.matches_pages_per_visit?(5)).to be true
    end

    it "does not match below threshold" do
      expect(goal.matches_pages_per_visit?(4)).to be false
    end
  end

  describe "inactive goals" do
    let(:goal) do
      create(:goal, property: property, goal_type: "url_match", active: false,
             match_config: { "pattern" => "/thank-you", "match_type" => "exact" })
    end
    let(:visitor) { create(:visitor, property: property) }
    let(:visit) { create(:visit, property: property, visitor: visitor) }

    it "does not match pageviews when inactive" do
      pv = build(:pageview, path: "/thank-you", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be false
    end

    it "does not match events when inactive" do
      goal.update!(goal_type: "event_match", match_config: { "category" => "x" })
      event = build(:event, category: "x", action: "y")
      expect(goal.matches_event?(event)).to be false
    end
  end

  describe "regex matching" do
    let(:visitor) { create(:visitor, property: property) }
    let(:visit) { create(:visit, property: property, visitor: visitor) }

    it "matches regex patterns" do
      goal = create(:goal, property: property, goal_type: "url_match",
                    match_config: { "pattern" => "/checkout/step\\d+", "match_type" => "regex" })
      pv = build(:pageview, path: "/checkout/step3", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be true
    end

    it "returns false for invalid regex" do
      goal = create(:goal, property: property, goal_type: "url_match",
                    match_config: { "pattern" => "[invalid", "match_type" => "regex" })
      pv = build(:pageview, path: "/anything", property: property, visit: visit, visitor: visitor)
      expect(goal.matches_pageview?(pv)).to be false
    end
  end

  describe "scopes" do
    it ".active returns only active goals" do
      active = create(:goal, property: property, active: true)
      create(:goal, property: property, active: false, key: "inactive_goal")
      expect(LocalAnalytics::Goal.active).to contain_exactly(active)
    end
  end

  describe "key generation" do
    it "auto-generates key from name" do
      goal = create(:goal, property: property, name: "Sign Up Now", key: nil)
      expect(goal.key).to eq("sign_up_now")
    end
  end
end
