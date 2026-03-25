# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin controllers", type: :request do
  let!(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }
  let(:visit) { create(:visit, property: property, visitor: visitor, started_at: 1.day.ago, ended_at: 1.day.ago + 5.minutes) }

  before do
    create(:pageview, property: property, visit: visit, visitor: visitor, viewed_at: 1.day.ago)
  end

  describe "Referrers" do
    it "GET /analytics/referrers" do
      get "/analytics/referrers", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Referrers")
    end

    it "GET /analytics/referrers/export.csv" do
      get "/analytics/referrers/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end
  end

  describe "Campaigns" do
    it "GET /analytics/campaigns" do
      get "/analytics/campaigns", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Campaigns")
    end

    it "GET /analytics/campaigns/export.csv" do
      get "/analytics/campaigns/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Events" do
    it "GET /analytics/events" do
      get "/analytics/events", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Events")
    end

    it "filters by category" do
      create(:event, property: property, visit: visit, visitor: visitor, category: "video", action: "play")
      get "/analytics/events", params: { property_id: property.id, category: "video" }
      expect(response).to have_http_status(:ok)
    end

    it "GET /analytics/events/export.csv" do
      get "/analytics/events/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Devices" do
    it "GET /analytics/devices" do
      get "/analytics/devices", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Devices")
    end

    it "renders browser dimension" do
      get "/analytics/devices", params: { property_id: property.id, dimension: "browser" }
      expect(response).to have_http_status(:ok)
    end

    it "renders os dimension" do
      get "/analytics/devices", params: { property_id: property.id, dimension: "os" }
      expect(response).to have_http_status(:ok)
    end

    it "GET /analytics/devices/export.csv" do
      get "/analytics/devices/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Locations" do
    it "GET /analytics/locations" do
      get "/analytics/locations", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Locations")
    end

    it "renders region dimension" do
      get "/analytics/locations", params: { property_id: property.id, dimension: "region" }
      expect(response).to have_http_status(:ok)
    end

    it "GET /analytics/locations/export.csv" do
      get "/analytics/locations/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Site Search" do
    it "GET /analytics/site_search" do
      get "/analytics/site_search", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Site Search")
    end

    it "GET /analytics/site_search/export.csv" do
      get "/analytics/site_search/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Real-Time" do
    it "GET /analytics/real_time" do
      get "/analytics/real_time", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Real-Time")
    end
  end
end
