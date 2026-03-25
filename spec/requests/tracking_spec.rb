# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Tracking endpoint", type: :request do
  let!(:property) { create(:property) }

  describe "POST /analytics/t" do
    let(:payload) do
      {
        type: "pageview",
        property_key: property.key,
        url: "https://example.com/test",
        path: "/test",
        title: "Test Page",
        visitor_id: "abc123"
      }
    end

    it "returns 204 no content" do
      post "/analytics/t", params: payload.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:no_content)
    end

    it "enqueues a processing job" do
      expect {
        post "/analytics/t", params: payload.to_json,
             headers: { "Content-Type" => "application/json" }
      }.to have_enqueued_job(LocalAnalytics::ProcessTrackingJob)
    end

    it "returns 400 for invalid JSON" do
      post "/analytics/t", params: "not json",
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 204 for missing property_key" do
      post "/analytics/t", params: { type: "pageview" }.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:bad_request)
    end

    context "with DNT header" do
      before { LocalAnalytics.configuration.respect_dnt = true }

      it "returns 204 without enqueuing when DNT is set" do
        expect {
          post "/analytics/t", params: payload.to_json,
               headers: { "Content-Type" => "application/json", "DNT" => "1" }
        }.not_to have_enqueued_job(LocalAnalytics::ProcessTrackingJob)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "GET /analytics/t (pixel)" do
    it "returns a 1x1 GIF" do
      get "/analytics/t", params: { pk: property.key, u: "https://example.com", p: "/" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("image/gif")
    end
  end
end
