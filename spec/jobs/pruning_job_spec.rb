# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::PruningJob, type: :job do
  let(:property) { create(:property, retention_days: 30) }
  let(:visitor) { create(:visitor, property: property) }

  describe "#perform" do
    before do
      # Old data (beyond retention)
      old_visit = create(:visit, property: property, visitor: visitor,
                         started_at: 60.days.ago, ended_at: 60.days.ago + 5.minutes)
      create(:pageview, property: property, visit: old_visit, visitor: visitor,
             viewed_at: 60.days.ago)
      create(:event, property: property, visit: old_visit, visitor: visitor,
             created_at: 60.days.ago)

      # Recent data (within retention)
      recent_visit = create(:visit, property: property, visitor: visitor,
                            started_at: 5.days.ago, ended_at: 5.days.ago + 5.minutes)
      create(:pageview, property: property, visit: recent_visit, visitor: visitor,
             viewed_at: 5.days.ago)
      create(:event, property: property, visit: recent_visit, visitor: visitor,
             created_at: 5.days.ago)
    end

    it "deletes old pageviews" do
      expect { described_class.perform_now }
        .to change(LocalAnalytics::Pageview, :count).by(-1)
    end

    it "deletes old events" do
      expect { described_class.perform_now }
        .to change(LocalAnalytics::Event, :count).by(-1)
    end

    it "deletes old visits" do
      expect { described_class.perform_now }
        .to change(LocalAnalytics::Visit, :count).by(-1)
    end

    it "keeps recent data" do
      described_class.perform_now
      expect(LocalAnalytics::Pageview.count).to eq(1)
      expect(LocalAnalytics::Event.count).to eq(1)
      expect(LocalAnalytics::Visit.count).to eq(1)
    end
  end
end
