# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class ReferrersReport < BaseReport
      def rows
        @rows ||= if use_aggregates?
          property.daily_referrer_aggregates
            .in_range(date_range.first, date_range.last)
            .group(:referrer_host, :referrer_source, :referrer_medium)
            .select(
              "referrer_host",
              "MAX(referrer_source) as referrer_source",
              "MAX(referrer_medium) as referrer_medium",
              "SUM(visits_count) as visits",
              "SUM(unique_visitors) as visitors",
              "SUM(bounces) as bounces",
              "CASE WHEN SUM(visits_count) > 0 THEN ROUND(SUM(bounces)::numeric / SUM(visits_count) * 100, 1) ELSE 0 END as bounce_rate"
            )
            .order(Arel.sql("SUM(visits_count) DESC"))
            .offset(offset).limit(per_page)
        else
          property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .where.not(referrer_host: [nil, ""])
            .group(:referrer_host, :referrer_source, :referrer_medium)
            .select(
              "referrer_host",
              "MAX(referrer_source) as referrer_source",
              "MAX(referrer_medium) as referrer_medium",
              "COUNT(*) as visits",
              "COUNT(DISTINCT visitor_id) as visitors",
              "SUM(CASE WHEN bounced THEN 1 ELSE 0 END) as bounces"
            )
            .order(Arel.sql("COUNT(*) DESC"))
            .offset(offset).limit(per_page)
        end
      end

      # Returns { referrer_host => previous_visits } for comparison column
      def comparison_by_host
        return {} unless comparing?

        @comparison_by_host ||= property.visits
          .in_range(comparison_range.first.beginning_of_day, comparison_range.last.end_of_day)
          .where.not(referrer_host: [nil, ""])
          .group(:referrer_host)
          .count
      end

      def by_medium
        property.visits
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .group(:referrer_medium)
          .order(Arel.sql("COUNT(*) DESC"))
          .pluck(:referrer_medium, Arel.sql("COUNT(*)"))
          .reject { |medium, _| medium.blank? }
      end

      private

      def csv_headers
        %w[referrer_host source medium visits visitors bounces bounce_rate]
      end

      def csv_rows
        rows.map do |r|
          [r.referrer_host, r.referrer_source, r.referrer_medium, r.visits, r.visitors, r.bounces, r.try(:bounce_rate)]
        end
      end
    end
  end
end
