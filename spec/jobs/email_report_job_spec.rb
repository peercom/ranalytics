# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::EmailReportJob, type: :job do
  let(:property) { create(:property) }

  def create_due_subscription(**attrs)
    sub = create(:report_subscription, property: property, **attrs)
    sub.update_column(:next_send_at, 1.hour.ago)
    sub
  end

  describe "#perform" do
    context "with specific subscription_id" do
      let!(:subscription) { create_due_subscription }

      it "sends the report email" do
        expect {
          described_class.perform_now(subscription_id: subscription.id)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "advances the schedule" do
        described_class.perform_now(subscription_id: subscription.id)
        subscription.reload
        expect(subscription.next_send_at).to be > Time.current
        expect(subscription.last_sent_at).to be_present
      end
    end

    context "without subscription_id (processes all due)" do
      let!(:due_sub) { create_due_subscription }
      let!(:future_sub) { create(:report_subscription, property: property) } # next_send_at in future

      it "sends only due subscriptions" do
        expect {
          described_class.perform_now
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "does not send future subscriptions" do
        described_class.perform_now
        expect(future_sub.reload.last_sent_at).to be_nil
      end
    end

    context "error handling" do
      let!(:subscription) { create_due_subscription }

      it "logs errors without raising" do
        allow(LocalAnalytics::ReportMailer).to receive(:scheduled_report).and_raise(StandardError, "SMTP down")
        expect { described_class.perform_now(subscription_id: subscription.id) }.not_to raise_error
      end
    end
  end
end
