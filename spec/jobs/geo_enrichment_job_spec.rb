# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::GeoEnrichmentJob, type: :job do
  let(:property) { create(:property) }
  let(:visitor) { create(:visitor, property: property) }

  describe "#perform" do
    let!(:visit) do
      create(:visit, property: property, visitor: visitor,
             ip: "8.8.8.8", country: nil, region: nil, city: nil)
    end

    it "does nothing when geo is disabled" do
      LocalAnalytics.configuration.enable_geo = false
      described_class.perform_now
      expect(visit.reload.country).to be_nil
      LocalAnalytics.configuration.enable_geo = false
    end

    context "with geo enabled" do
      let(:provider) { instance_double(LocalAnalytics::Geo::NullProvider) }

      before do
        LocalAnalytics.configuration.enable_geo = true
        LocalAnalytics.configuration.geo_provider = provider
      end

      after do
        LocalAnalytics.configuration.enable_geo = false
        LocalAnalytics.configuration.geo_provider = nil
      end

      it "enriches visits with geo data" do
        allow(provider).to receive(:lookup).with("8.8.8.8").and_return(
          { country: "US", region: "CA", city: "Mountain View" }
        )

        described_class.perform_now
        visit.reload
        expect(visit.country).to eq("US")
        expect(visit.region).to eq("CA")
        expect(visit.city).to eq("Mountain View")
      end

      it "skips visits without IP" do
        visit.update_column(:ip, nil)
        allow(provider).to receive(:lookup)

        described_class.perform_now
        expect(provider).not_to have_received(:lookup)
      end

      it "skips visits already enriched" do
        visit.update_columns(country: "DE")
        allow(provider).to receive(:lookup)

        described_class.perform_now
        expect(provider).not_to have_received(:lookup)
      end
    end
  end
end
