# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class PagesReport < BaseReport
      def rows
        @rows ||= case report_type
        when "entry" then entry_pages
        when "exit" then exit_pages
        else all_pages
        end
      end

      # Returns a hash of { path => previous_pageviews } for comparison column.
      # Only computed when comparing.
      def comparison_by_path
        return {} unless comparing?

        @comparison_by_path ||= if use_aggregates_for_comparison?
          property.daily_page_aggregates
            .in_range(comparison_range.first, comparison_range.last)
            .group(:path)
            .sum(:pageviews_count)
        else
          property.pageviews
            .in_range(comparison_range.first.beginning_of_day, comparison_range.last.end_of_day)
            .group(:path)
            .count
        end
      end

      def total_count
        @total_count ||= case report_type
        when "entry"
          property.daily_page_aggregates.in_range(date_range.first, date_range.last)
            .where("entries > 0").select(:path).distinct.count
        when "exit"
          property.daily_page_aggregates.in_range(date_range.first, date_range.last)
            .where("exits > 0").select(:path).distinct.count
        else
          property.daily_page_aggregates.in_range(date_range.first, date_range.last)
            .select(:path).distinct.count
        end
      end

      private

      def report_type
        @options[:report_type] || "all"
      end

      def all_pages
        if use_aggregates?
          property.daily_page_aggregates
            .in_range(date_range.first, date_range.last)
            .group(:path)
            .select(
              "path",
              "SUM(pageviews_count) as pageviews",
              "SUM(unique_visitors) as visitors",
              "SUM(entries) as entries",
              "SUM(exits) as exits",
              "SUM(bounces) as bounces",
              "CASE WHEN SUM(entries) > 0 THEN ROUND(SUM(bounces)::numeric / SUM(entries) * 100, 1) ELSE 0 END as bounce_rate"
            )
            .order(Arel.sql("SUM(pageviews_count) DESC"))
            .offset(offset).limit(per_page)
        else
          property.pageviews
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .group(:path)
            .select(
              "path",
              "COUNT(*) as pageviews",
              "COUNT(DISTINCT visitor_id) as visitors"
            )
            .order(Arel.sql("COUNT(*) DESC"))
            .offset(offset).limit(per_page)
        end
      end

      def entry_pages
        property.daily_page_aggregates
          .in_range(date_range.first, date_range.last)
          .where("entries > 0")
          .group(:path)
          .select(
            "path",
            "SUM(entries) as entries",
            "SUM(bounces) as bounces",
            "CASE WHEN SUM(entries) > 0 THEN ROUND(SUM(bounces)::numeric / SUM(entries) * 100, 1) ELSE 0 END as bounce_rate"
          )
          .order(Arel.sql("SUM(entries) DESC"))
          .offset(offset).limit(per_page)
      end

      def exit_pages
        property.daily_page_aggregates
          .in_range(date_range.first, date_range.last)
          .where("exits > 0")
          .group(:path)
          .select(
            "path",
            "SUM(exits) as exits",
            "SUM(pageviews_count) as pageviews",
            "CASE WHEN SUM(pageviews_count) > 0 THEN ROUND(SUM(exits)::numeric / SUM(pageviews_count) * 100, 1) ELSE 0 END as exit_rate"
          )
          .order(Arel.sql("SUM(exits) DESC"))
          .offset(offset).limit(per_page)
      end

      def csv_headers
        case report_type
        when "entry" then %w[path entries bounces bounce_rate]
        when "exit" then %w[path exits pageviews exit_rate]
        else %w[path pageviews visitors entries exits bounce_rate]
        end
      end

      def csv_rows
        rows.map do |r|
          case report_type
          when "entry"
            [r.path, r.entries, r.bounces, r.bounce_rate]
          when "exit"
            [r.path, r.exits, r.pageviews, r.exit_rate]
          else
            [r.path, r.pageviews, r.visitors, r.try(:entries), r.try(:exits), r.try(:bounce_rate)]
          end
        end
      end
    end
  end
end
