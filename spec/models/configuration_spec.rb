# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Configuration do
  let(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.cookie_name).to eq("_la_vid")
    expect(config.visit_timeout).to eq(30.minutes)
    expect(config.respect_dnt).to be true
    expect(config.ip_anonymization).to be true
    expect(config.store_full_ip).to be false
    expect(config.store_query_parameters).to be false
    expect(config.bot_filtering).to be true
    expect(config.retention_period).to eq(24.months)
  end

  it "allows configuration via block" do
    LocalAnalytics.configure do |c|
      c.cookie_name = "_custom"
      c.visit_timeout = 45.minutes
    end

    expect(LocalAnalytics.configuration.cookie_name).to eq("_custom")
    expect(LocalAnalytics.configuration.visit_timeout).to eq(45.minutes)

    LocalAnalytics.reset_configuration!
  end

  it "returns NullProvider when no geo provider set" do
    config.geo_provider = nil
    expect(config.geo_provider_instance).to be_a(LocalAnalytics::Geo::NullProvider)
  end
end
