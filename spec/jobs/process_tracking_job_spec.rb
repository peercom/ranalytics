# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::ProcessTrackingJob, type: :job do
  let!(:property) { create(:property) }

  it "calls TrackingProcessor#process" do
    payload = { "type" => "pageview", "property_key" => property.key, "url" => "/", "path" => "/" }
    processor = instance_double(LocalAnalytics::Services::TrackingProcessor, process: nil)
    allow(LocalAnalytics::Services::TrackingProcessor).to receive(:new).with(payload).and_return(processor)

    described_class.perform_now(payload)

    expect(processor).to have_received(:process)
  end

  it "discards on StandardError without raising" do
    payload = { "type" => "pageview", "property_key" => "bad" }
    allow(LocalAnalytics::Services::TrackingProcessor).to receive(:new).and_raise(StandardError, "boom")

    expect { described_class.perform_now(payload) }.not_to raise_error
  end
end
