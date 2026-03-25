# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class SiteSearchReport < BaseReport
      def rows
        @rows ||= property.events
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .where(category: "site_search", action: "search")
          .group(:name)
          .select(
            "name as search_term",
            "COUNT(*) as searches",
            "COUNT(DISTINCT visitor_id) as visitors"
          )
          .order(Arel.sql("COUNT(*) DESC"))
          .offset(offset).limit(per_page)
      end

      private

      def csv_headers
        %w[search_term searches visitors]
      end

      def csv_rows
        rows.map { |r| [r.search_term, r.searches, r.visitors] }
      end
    end
  end
end
