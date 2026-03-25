# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class LocationsReport < BaseReport
      def rows
        @rows ||= if use_aggregates?
          property.daily_location_aggregates
            .in_range(date_range.first, date_range.last)
            .group(dimension)
            .select(
              "#{dimension}",
              "SUM(visits_count) as visits",
              "SUM(unique_visitors) as visitors"
            )
            .order(Arel.sql("SUM(visits_count) DESC"))
        else
          property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .where.not(dimension => [nil, ""])
            .group(dimension)
            .select(
              "#{dimension}",
              "COUNT(*) as visits",
              "COUNT(DISTINCT visitor_id) as visitors"
            )
            .order(Arel.sql("COUNT(*) DESC"))
        end
      end

      private

      def dimension
        d = @options[:dimension] || "country"
        %w[country region city].include?(d) ? d : "country"
      end

      def csv_headers
        [dimension, "visits", "visitors"]
      end

      def csv_rows
        rows.map { |r| [r.send(dimension), r.visits, r.visitors] }
      end
    end
  end
end
