# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class EventsReport < BaseReport
      def rows
        @rows ||= begin
          scope = if use_aggregates?
            base = property.daily_event_aggregates.in_range(date_range.first, date_range.last)
            base = base.where(category: category_filter) if category_filter.present?
            base.group(:category, :action)
              .select(
                "category", "action",
                "SUM(events_count) as total_events",
                "SUM(unique_visitors) as visitors",
                "SUM(total_value) as total_value"
              )
              .order(Arel.sql("SUM(events_count) DESC"))
          else
            base = property.events.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            base = base.where(category: category_filter) if category_filter.present?
            base.group(:category, :action)
              .select(
                "category", "action",
                "COUNT(*) as total_events",
                "COUNT(DISTINCT visitor_id) as visitors",
                "SUM(COALESCE(value, 0)) as total_value"
              )
              .order(Arel.sql("COUNT(*) DESC"))
          end
          scope.offset(offset).limit(per_page)
        end
      end

      def categories
        property.events
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .distinct.pluck(:category).sort
      end

      private

      def category_filter
        @options[:category_filter]
      end

      def csv_headers
        %w[category action events visitors total_value]
      end

      def csv_rows
        rows.map { |r| [r.category, r.action, r.total_events, r.visitors, r.total_value] }
      end
    end
  end
end
