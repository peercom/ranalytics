# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Goals", type: :request do
  let!(:property) { create(:property) }
  let!(:goal) { create(:goal, property: property, name: "Signup", key: "signup") }

  describe "GET /analytics/goals" do
    it "lists goals" do
      get "/analytics/goals", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Signup")
    end
  end

  describe "GET /analytics/goals/:id" do
    it "shows goal detail" do
      get "/analytics/goals/#{goal.id}", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Signup")
    end
  end

  describe "GET /analytics/goals/new" do
    it "renders new goal form" do
      get "/analytics/goals/new", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Goal")
    end
  end

  describe "POST /analytics/goals" do
    it "creates a goal" do
      expect {
        post "/analytics/goals", params: {
          property_id: property.id,
          goal: { name: "Purchase", goal_type: "manual", key: "purchase" }
        }
      }.to change(LocalAnalytics::Goal, :count).by(1)
      expect(response).to redirect_to(/goals/)
    end

    it "re-renders on invalid input" do
      post "/analytics/goals", params: {
        property_id: property.id,
        goal: { name: "", goal_type: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /analytics/goals/:id/edit" do
    it "renders edit form" do
      get "/analytics/goals/#{goal.id}/edit", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Goal")
    end
  end

  describe "PATCH /analytics/goals/:id" do
    it "updates the goal" do
      patch "/analytics/goals/#{goal.id}", params: {
        property_id: property.id,
        goal: { name: "Signup V2" }
      }
      expect(response).to redirect_to(/goals/)
      expect(goal.reload.name).to eq("Signup V2")
    end
  end

  describe "DELETE /analytics/goals/:id" do
    it "deletes the goal" do
      expect {
        delete "/analytics/goals/#{goal.id}", params: { property_id: property.id }
      }.to change(LocalAnalytics::Goal, :count).by(-1)
    end
  end

  describe "GET /analytics/goals/export" do
    it "exports CSV" do
      get "/analytics/goals/export", params: { property_id: property.id, format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
    end
  end
end
