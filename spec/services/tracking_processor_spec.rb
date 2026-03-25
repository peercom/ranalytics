# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Services::TrackingProcessor do
  let(:property) { create(:property) }

  describe "#process" do
    context "pageview tracking" do
      let(:payload) do
        {
          type: "pageview",
          property_key: property.key,
          url: "https://example.com/about",
          path: "/about",
          title: "About Us",
          visitor_id: "test_visitor_123",
          ip: "192.168.1.100",
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
          referrer: "https://google.com/search?q=test"
        }
      end

      it "creates a visitor" do
        expect { described_class.new(payload).process }
          .to change(LocalAnalytics::Visitor, :count).by(1)
      end

      it "creates a visit" do
        expect { described_class.new(payload).process }
          .to change(LocalAnalytics::Visit, :count).by(1)
      end

      it "creates a pageview" do
        expect { described_class.new(payload).process }
          .to change(LocalAnalytics::Pageview, :count).by(1)

        pv = LocalAnalytics::Pageview.last
        expect(pv.path).to eq("/about")
        expect(pv.title).to eq("About Us")
      end

      it "reuses existing visitor on subsequent pageviews" do
        described_class.new(payload).process
        described_class.new(payload.merge(path: "/contact", url: "https://example.com/contact")).process

        expect(LocalAnalytics::Visitor.count).to eq(1)
        expect(LocalAnalytics::Pageview.count).to eq(2)
      end

      it "reuses existing visit within timeout window" do
        described_class.new(payload).process
        described_class.new(payload.merge(path: "/contact", url: "https://example.com/contact")).process

        expect(LocalAnalytics::Visit.count).to eq(1)
        expect(LocalAnalytics::Visit.last.bounced).to be false
      end

      it "parses referrer information" do
        described_class.new(payload).process

        visit = LocalAnalytics::Visit.last
        expect(visit.referrer_host).to eq("google.com")
        expect(visit.referrer_source).to eq("google")
        expect(visit.referrer_medium).to eq("search")
        expect(visit.search_engine).to eq("google")
      end

      it "captures UTM parameters" do
        described_class.new(payload.merge(
          utm_source: "newsletter",
          utm_medium: "email",
          utm_campaign: "spring_2026"
        )).process

        visit = LocalAnalytics::Visit.last
        expect(visit.utm_source).to eq("newsletter")
        expect(visit.utm_medium).to eq("email")
        expect(visit.utm_campaign).to eq("spring_2026")
      end
    end

    context "event tracking" do
      let(:visitor) { create(:visitor, property: property, visitor_token: "test_visitor_123") }
      let!(:visit) { create(:visit, property: property, visitor: visitor, started_at: 1.minute.ago, ended_at: 1.second.ago) }
      let(:payload) do
        {
          type: "event",
          property_key: property.key,
          category: "video",
          action: "play",
          name: "intro_video",
          value: 1.0,
          visitor_id: "test_visitor_123",
          user_agent: "Mozilla/5.0"
        }
      end

      it "creates an event" do
        expect { described_class.new(payload).process }
          .to change(LocalAnalytics::Event, :count).by(1)

        event = LocalAnalytics::Event.last
        expect(event.category).to eq("video")
        expect(event.action).to eq("play")
        expect(event.name).to eq("intro_video")
      end
    end

    context "conversion tracking" do
      let(:visitor) { create(:visitor, property: property, visitor_token: "test_visitor_123") }
      let!(:visit) { create(:visit, property: property, visitor: visitor, started_at: 1.minute.ago, ended_at: 1.second.ago) }
      let!(:goal) { create(:goal, property: property, key: "signup", goal_type: "manual") }
      let(:payload) do
        {
          type: "conversion",
          property_key: property.key,
          goal_key: "signup",
          visitor_id: "test_visitor_123",
          user_agent: "Mozilla/5.0",
          revenue: 49.0
        }
      end

      it "creates a conversion" do
        expect { described_class.new(payload).process }
          .to change(LocalAnalytics::Conversion, :count).by(1)

        conversion = LocalAnalytics::Conversion.last
        expect(conversion.goal).to eq(goal)
        expect(conversion.revenue).to eq(49.0)
      end

      it "prevents duplicate conversions per visit" do
        described_class.new(payload).process
        described_class.new(payload).process

        expect(LocalAnalytics::Conversion.count).to eq(1)
      end
    end

    context "invalid payloads" do
      it "ignores missing property_key" do
        expect { described_class.new({ type: "pageview" }).process }
          .not_to change(LocalAnalytics::Pageview, :count)
      end

      it "ignores unknown property" do
        expect { described_class.new({ type: "pageview", property_key: "nonexistent", url: "/", path: "/" }).process }
          .not_to change(LocalAnalytics::Pageview, :count)
      end

      it "ignores invalid type" do
        expect { described_class.new({ type: "invalid", property_key: property.key }).process }
          .not_to change(LocalAnalytics::Pageview, :count)
      end
    end
  end
end
