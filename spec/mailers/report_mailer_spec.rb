# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::ReportMailer, type: :mailer do
  let(:property) { create(:property, name: "Test Site") }
  let!(:subscription) do
    create(:report_subscription, property: property,
           report_type: "dashboard", recipients: "alice@example.com, bob@example.com",
           name: "Weekly Dashboard")
  end

  describe "#scheduled_report" do
    let(:mail) { described_class.scheduled_report(subscription.id) }

    it "sends to all recipients" do
      expect(mail.to).to eq(["alice@example.com", "bob@example.com"])
    end

    it "sets the from address from config" do
      LocalAnalytics.configuration.email_from = "reports@myapp.com"
      expect(mail.from).to eq(["reports@myapp.com"])
      LocalAnalytics.configuration.email_from = "analytics@example.com"
    end

    it "includes report title in subject" do
      expect(mail.subject).to include("Dashboard Report")
      expect(mail.subject).to include("Test Site")
    end

    it "attaches a CSV file" do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments.first
      expect(attachment.filename).to end_with(".csv")
      expect(attachment.mime_type).to eq("text/csv")
    end

    it "includes HTML body" do
      html = mail.html_part.body.to_s
      expect(html).to include("Test Site")
      expect(html).to include("Weekly Dashboard")
    end

    it "includes text body" do
      text = mail.text_part.body.to_s
      expect(text).to include("Unique Visitors")
      expect(text).to include("Test Site")
    end

    context "with dashboard report" do
      it "includes metric summaries in HTML" do
        html = mail.html_part.body.to_s
        expect(html).to include("Unique Visitors")
        expect(html).to include("Pageviews")
        expect(html).to include("Bounce Rate")
      end
    end

    context "with non-dashboard report" do
      let!(:subscription) do
        create(:report_subscription, property: property,
               report_type: "pages", recipients: "test@example.com",
               name: "Pages Report")
      end

      it "includes generic body with CSV reference" do
        html = mail.html_part.body.to_s
        expect(html).to include("Pages")
        expect(html).to include("attached as a CSV")
      end
    end
  end
end
