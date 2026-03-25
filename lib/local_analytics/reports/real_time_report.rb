# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class RealTimeReport < BaseReport
      def initialize(property:)
        @property = property
      end

      def active_visitors_5min
        property.pageviews.where("viewed_at > ?", 5.minutes.ago).distinct.count(:visitor_id)
      end

      def active_visitors_30min
        property.pageviews.where("viewed_at > ?", 30.minutes.ago).distinct.count(:visitor_id)
      end

      def top_pages(limit: 10)
        property.pageviews
          .where("viewed_at > ?", 30.minutes.ago)
          .group(:path)
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(limit)
          .pluck(:path, Arel.sql("COUNT(*)"))
      end

      def top_referrers(limit: 10)
        property.visits
          .where("started_at > ?", 30.minutes.ago)
          .where.not(referrer_host: [nil, ""])
          .group(:referrer_host)
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(limit)
          .pluck(:referrer_host, Arel.sql("COUNT(*)"))
      end

      def top_campaigns(limit: 5)
        property.visits
          .where("started_at > ?", 30.minutes.ago)
          .where.not(utm_campaign: [nil, ""])
          .group(:utm_campaign)
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(limit)
          .pluck(:utm_campaign, Arel.sql("COUNT(*)"))
      end

      def recent_events(limit: 20)
        property.events.order(created_at: :desc).limit(limit)
      end

      def recent_pageviews(limit: 20)
        property.pageviews.order(viewed_at: :desc).limit(limit)
      end
    end
  end
end
