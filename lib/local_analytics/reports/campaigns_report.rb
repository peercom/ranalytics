# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class CampaignsReport < BaseReport
      def rows
        @rows ||= if use_aggregates?
          property.daily_referrer_aggregates
            .in_range(date_range.first, date_range.last)
            .where.not(utm_campaign: [nil, ""])
            .group(:utm_source, :utm_medium, :utm_campaign)
            .select(
              "utm_source", "utm_medium", "utm_campaign",
              "SUM(visits_count) as visits",
              "SUM(unique_visitors) as visitors",
              "SUM(bounces) as bounces"
            )
            .order(Arel.sql("SUM(visits_count) DESC"))
            .offset(offset).limit(per_page)
        else
          property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .where.not(utm_campaign: [nil, ""])
            .group(:utm_source, :utm_medium, :utm_campaign)
            .select(
              "utm_source", "utm_medium", "utm_campaign",
              "COUNT(*) as visits",
              "COUNT(DISTINCT visitor_id) as visitors",
              "SUM(CASE WHEN bounced THEN 1 ELSE 0 END) as bounces"
            )
            .order(Arel.sql("COUNT(*) DESC"))
            .offset(offset).limit(per_page)
        end
      end

      private

      def csv_headers
        %w[utm_source utm_medium utm_campaign visits visitors bounces]
      end

      def csv_rows
        rows.map { |r| [r.utm_source, r.utm_medium, r.utm_campaign, r.visits, r.visitors, r.bounces] }
      end
    end
  end
end
