# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Visitor Log", type: :request do
  let!(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let!(:visit) do
    create(:visit, property: property, visitor: visitor,
           started_at: 1.day.ago, ended_at: 1.day.ago + 5.minutes,
           browser: "Chrome", os: "macOS", device_type: "desktop",
           referrer_host: "google.com")
  end
  let!(:pageview) do
    create(:pageview, property: property, visit: visit, visitor: visitor,
           path: "/home", viewed_at: 1.day.ago)
  end
  let!(:event) do
    create(:event, property: property, visit: visit, visitor: visitor,
           category: "click", action: "cta", created_at: 1.day.ago)
  end

  describe "GET /analytics/visitor_log" do
    it "renders the visitor log" do
      get "/analytics/visitor_log", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visitor Log")
    end

    it "shows visit details" do
      get "/analytics/visitor_log", params: { property_id: property.id }
      expect(response.body).to include("Chrome")
      expect(response.body).to include("google.com")
    end

    it "shows session timeline in expandable details" do
      get "/analytics/visitor_log", params: { property_id: property.id }
      expect(response.body).to include("/home")
      expect(response.body).to include("click")
    end

    it "links to visitor profile" do
      get "/analytics/visitor_log", params: { property_id: property.id }
      expect(response.body).to include(visitor.visitor_token.first(8))
    end

    it "paginates results" do
      get "/analytics/visitor_log", params: { property_id: property.id, page: 1 }
      expect(response).to have_http_status(:ok)
    end

    it "filters by date range" do
      get "/analytics/visitor_log", params: {
        property_id: property.id,
        from: 2.days.ago.to_date,
        to: Date.current
      }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 visits")
    end

    it "shows empty state for no visits" do
      get "/analytics/visitor_log", params: {
        property_id: property.id,
        from: 1.year.ago.to_date,
        to: 1.year.ago.to_date
      }
      expect(response.body).to include("No visits")
    end
  end
end
