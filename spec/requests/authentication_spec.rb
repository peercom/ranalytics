# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Authentication", type: :request do
  let!(:property) { create(:property) }

  context "with authenticate_with configured" do
    before do
      LocalAnalytics.configuration.authenticate_with = ->(controller) {
        controller.head(:unauthorized)
      }
    end

    after do
      LocalAnalytics.configuration.authenticate_with = nil
    end

    it "blocks access to dashboard" do
      get "/analytics", params: { property_id: property.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it "blocks access to reports" do
      get "/analytics/pages", params: { property_id: property.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it "does NOT block tracking endpoint" do
      post "/analytics/t", params: { type: "pageview", property_key: property.key }.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:no_content)
    end
  end

  context "without authenticate_with" do
    before { LocalAnalytics.configuration.authenticate_with = nil }

    it "allows access to dashboard" do
      get "/analytics", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
    end
  end
end
