# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Visitor Profiles", type: :request do
  let!(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property, returning: true) }
  let!(:visit1) do
    create(:visit, property: property, visitor: visitor,
           started_at: 3.days.ago, ended_at: 3.days.ago + 10.minutes,
           browser: "Chrome", os: "macOS", referrer_host: "google.com")
  end
  let!(:visit2) do
    create(:visit, property: property, visitor: visitor,
           started_at: 1.day.ago, ended_at: 1.day.ago + 5.minutes,
           browser: "Safari", os: "iOS")
  end
  let!(:pv1) { create(:pageview, property: property, visit: visit1, visitor: visitor, path: "/home", viewed_at: 3.days.ago) }
  let!(:pv2) { create(:pageview, property: property, visit: visit1, visitor: visitor, path: "/about", url: "https://example.com/about", viewed_at: 3.days.ago + 2.minutes) }
  let!(:pv3) { create(:pageview, property: property, visit: visit2, visitor: visitor, path: "/pricing", url: "https://example.com/pricing", viewed_at: 1.day.ago) }
  let!(:event1) { create(:event, property: property, visit: visit1, visitor: visitor, category: "click", action: "cta", created_at: 3.days.ago + 1.minute) }

  let!(:goal) { create(:goal, property: property, name: "Signup") }
  let!(:conversion) { create(:conversion, property: property, visit: visit1, visitor: visitor, goal: goal, revenue: 25.0, converted_at: 3.days.ago + 5.minutes) }

  describe "GET /analytics/visitors/:id" do
    it "renders the visitor profile" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visitor.visitor_token.first(12))
    end

    it "shows summary metrics" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      body = response.body
      expect(body).to include("Returning")
      # Total visits = 2
      expect(body).to include("2")
    end

    it "shows visit history with timelines" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      body = response.body
      expect(body).to include("/home")
      expect(body).to include("/about")
      expect(body).to include("/pricing")
      expect(body).to include("click")
      expect(body).to include("Signup")
    end

    it "shows visit device and referrer info" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      body = response.body
      expect(body).to include("Chrome")
      expect(body).to include("Safari")
      expect(body).to include("google.com")
    end

    it "shows conversion revenue" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      expect(response.body).to include("$25.00")
    end

    it "links back to visitor log" do
      get "/analytics/visitors/#{visitor.id}", params: { property_id: property.id }
      expect(response.body).to include("Visitor Log")
    end
  end
end
