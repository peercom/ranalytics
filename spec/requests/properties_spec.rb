# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Properties", type: :request do
  describe "GET /analytics/properties" do
    it "lists properties" do
      create(:property, name: "My Site")
      get "/analytics/properties"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Site")
    end
  end

  describe "GET /analytics/properties/new" do
    it "renders new form" do
      get "/analytics/properties/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Property")
    end
  end

  describe "POST /analytics/properties" do
    it "creates a property" do
      expect {
        post "/analytics/properties", params: {
          property: { name: "Docs Site", timezone: "UTC" }
        }
      }.to change(LocalAnalytics::Property, :count).by(1)
      expect(response).to redirect_to(/properties/)
    end

    it "re-renders on invalid input" do
      post "/analytics/properties", params: {
        property: { name: "", timezone: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /analytics/properties/:id" do
    it "shows property detail" do
      prop = create(:property)
      get "/analytics/properties/#{prop.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(prop.key)
    end
  end

  describe "GET /analytics/properties/:id/edit" do
    it "renders edit form" do
      prop = create(:property)
      get "/analytics/properties/#{prop.id}/edit"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /analytics/properties/:id" do
    it "updates the property" do
      prop = create(:property, name: "Old Name")
      patch "/analytics/properties/#{prop.id}", params: {
        property: { name: "New Name" }
      }
      expect(response).to redirect_to(/properties/)
      expect(prop.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /analytics/properties/:id" do
    it "deletes the property" do
      prop = create(:property)
      expect {
        delete "/analytics/properties/#{prop.id}"
      }.to change(LocalAnalytics::Property, :count).by(-1)
    end
  end
end
