# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Report Subscriptions", type: :request do
  let!(:property) { create(:property) }

  describe "GET /analytics/report_subscriptions" do
    it "lists subscriptions" do
      create(:report_subscription, property: property, name: "Weekly Dashboard")
      get "/analytics/report_subscriptions", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weekly Dashboard")
    end
  end

  describe "GET /analytics/report_subscriptions/new" do
    it "renders new form" do
      get "/analytics/report_subscriptions/new", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Email Report")
    end
  end

  describe "POST /analytics/report_subscriptions" do
    it "creates a subscription" do
      expect {
        post "/analytics/report_subscriptions", params: {
          property_id: property.id,
          report_subscription: {
            name: "Daily Pages",
            recipients: "team@example.com",
            frequency: "daily",
            report_type: "pages",
            hour_of_day: 9
          }
        }
      }.to change(LocalAnalytics::ReportSubscription, :count).by(1)
      expect(response).to redirect_to(/report_subscriptions/)
    end

    it "re-renders on invalid input" do
      post "/analytics/report_subscriptions", params: {
        property_id: property.id,
        report_subscription: { name: "", recipients: "", frequency: "", report_type: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /analytics/report_subscriptions/:id" do
    it "shows subscription detail" do
      sub = create(:report_subscription, property: property)
      get "/analytics/report_subscriptions/#{sub.id}", params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(sub.name)
    end
  end

  describe "PATCH /analytics/report_subscriptions/:id" do
    it "updates the subscription" do
      sub = create(:report_subscription, property: property, name: "Old Name")
      patch "/analytics/report_subscriptions/#{sub.id}", params: {
        property_id: property.id,
        report_subscription: { name: "New Name" }
      }
      expect(response).to redirect_to(/report_subscriptions/)
      expect(sub.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /analytics/report_subscriptions/:id" do
    it "deletes the subscription" do
      sub = create(:report_subscription, property: property)
      expect {
        delete "/analytics/report_subscriptions/#{sub.id}", params: { property_id: property.id }
      }.to change(LocalAnalytics::ReportSubscription, :count).by(-1)
    end
  end

  describe "POST /analytics/report_subscriptions/:id/send_now" do
    it "enqueues an email report job" do
      sub = create(:report_subscription, property: property)
      expect {
        post "/analytics/report_subscriptions/#{sub.id}/send_now", params: { property_id: property.id }
      }.to have_enqueued_job(LocalAnalytics::EmailReportJob)
      expect(response).to redirect_to(/report_subscriptions/)
    end
  end
end
