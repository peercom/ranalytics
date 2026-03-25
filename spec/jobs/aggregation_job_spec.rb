# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::AggregationJob, type: :job do
  let!(:property) { create(:property) }

  it "enqueues successfully" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job(described_class)
  end

  it "calls aggregator for each active property" do
    allow(LocalAnalytics::Services::Aggregator).to receive_message_chain(:new, :aggregate_all)
    described_class.perform_now
    expect(LocalAnalytics::Services::Aggregator).to have_received(:new)
      .with(property: property, date: Date.yesterday)
  end

  it "respects aggregation_enabled config" do
    LocalAnalytics.configuration.aggregation_enabled = false
    allow(LocalAnalytics::Services::Aggregator).to receive(:new)
    described_class.perform_now
    expect(LocalAnalytics::Services::Aggregator).not_to have_received(:new)
    LocalAnalytics.configuration.aggregation_enabled = true
  end
end
