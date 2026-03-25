# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pages", type: :request do
  let!(:property) { create(:property) }

  describe "GET /analytics/pages" do
    it "renders all pages" do
      get "/analytics/pages", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pages")
    end

    it "renders entry pages" do
      get "/analytics/pages", params: { property_id: property.id, type: "entry" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Entry Pages")
    end

    it "renders exit pages" do
      get "/analytics/pages", params: { property_id: property.id, type: "exit" }
      expect(response).to have_http_status(:ok)
    end

    it "renders with comparison" do
      get "/analytics/pages", params: { property_id: property.id, compare: "previous" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /analytics/pages/export" do
    it "exports CSV" do
      get "/analytics/pages/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end
  end
end
