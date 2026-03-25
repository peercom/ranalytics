# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dashboard", type: :request do
  let!(:property) { create(:property) }

  describe "GET /analytics" do
    it "renders the dashboard" do
      get "/analytics"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard")
    end

    it "renders with date range params" do
      get "/analytics", params: { from: 7.days.ago.to_date, to: Date.current, property_id: property.id }
      expect(response).to have_http_status(:ok)
    end

    it "renders with comparison enabled" do
      get "/analytics", params: { from: 7.days.ago.to_date, to: Date.current, compare: "previous", property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Comparing")
    end

    it "renders with year comparison" do
      get "/analytics", params: { compare: "year", property_id: property.id }
      expect(response).to have_http_status(:ok)
    end

    it "handles invalid date params gracefully" do
      get "/analytics", params: { from: "invalid", to: "bad", property_id: property.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /analytics/dashboard/export" do
    it "exports CSV" do
      get "/analytics/dashboard/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end
  end
end
