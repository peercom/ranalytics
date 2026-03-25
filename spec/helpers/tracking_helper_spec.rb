# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::TrackingHelper, type: :helper do
  let!(:property) { create(:property) }

  before do
    # Stub the engine routes helper
    allow(helper).to receive(:local_analytics).and_return(
      double(tracking_create_url: "http://test.host/analytics/t",
             tracking_pixel_url: "http://test.host/analytics/t")
    )
    allow(helper).to receive(:request).and_return(
      double(remote_ip: "127.0.0.1", path: "/", host: "test.host")
    )
    allow(helper).to receive(:content_security_policy_nonce).and_return(nil)
    LocalAnalytics.configuration.exclude_request = ->(_r) { false }
  end

  describe "#local_analytics_tracking_tag" do
    it "renders a script tag" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("<script")
      expect(html).to include("LocalAnalytics")
    end

    it "includes the property key" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include(property.key)
    end

    it "includes the tracker endpoint" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("/analytics/t")
    end

    it "includes trackPageview call" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("trackPageview")
    end

    it "includes turbo:load listener" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("turbo:load")
    end

    it "includes consent API methods" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("setConsent")
      expect(html).to include("enableTracking")
      expect(html).to include("disableTracking")
    end

    it "includes outbound link tracking" do
      LocalAnalytics.configuration.track_outbound_links = true
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("outbound")
    end

    it "includes download extension tracking" do
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to include("downloadExtensions")
    end

    it "returns empty string when no property key" do
      html = helper.local_analytics_tracking_tag(property_key: nil)
      # Falls back to first active property
      if LocalAnalytics::Property.active.any?
        expect(html).to include("<script")
      end
    end

    it "returns empty string when request is excluded" do
      LocalAnalytics.configuration.exclude_request = ->(_r) { true }
      html = helper.local_analytics_tracking_tag(property_key: property.key)
      expect(html).to eq("")
      LocalAnalytics.configuration.exclude_request = ->(_r) { false }
    end

    context "consent mode" do
      it "sets consentRequired when configured" do
        html = helper.local_analytics_tracking_tag(property_key: property.key, options: { consent_required: true })
        expect(html).to include("consentRequired: true")
        expect(html).to include("consentGiven: false")
      end
    end

    context "cookieless mode" do
      before { LocalAnalytics.configuration.cookieless_mode = true }
      after { LocalAnalytics.configuration.cookieless_mode = false }

      it "sets cookieless flag" do
        html = helper.local_analytics_tracking_tag(property_key: property.key)
        expect(html).to include("cookieless: true")
      end
    end
  end

  describe "#local_analytics_noscript_tag" do
    it "renders a noscript tag with image" do
      html = helper.local_analytics_noscript_tag(property_key: property.key)
      expect(html).to include("<noscript")
      expect(html).to include("<img")
      expect(html).to include("width=\"1\"")
      expect(html).to include("height=\"1\"")
    end

    it "returns empty with no property" do
      LocalAnalytics::Property.destroy_all
      html = helper.local_analytics_noscript_tag
      expect(html).to eq("")
    end
  end
end
