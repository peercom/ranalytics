# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class DashboardReport < BaseReport
      def total_pageviews
        @total_pageviews ||= if use_aggregates?
          property.daily_page_aggregates.in_range(date_range.first, date_range.last).sum(:pageviews_count)
        else
          property.pageviews.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day).count
        end
      end

      def total_visits
        @total_visits ||= property.visits.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day).count
      end

      def total_unique_visitors
        @total_unique_visitors ||= property.visits
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .distinct.count(:visitor_id)
      end

      def bounce_rate
        return 0.0 if total_visits.zero?

        bounced = property.visits
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .bounced.count
        (bounced.to_f / total_visits * 100).round(1)
      end

      def avg_visit_duration
        @avg_visit_duration ||= begin
          avg = property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .where.not(ended_at: nil)
            .average(Arel.sql("EXTRACT(EPOCH FROM (ended_at - started_at))"))
          (avg || 0).to_f.round(0)
        end
      end

      def avg_pages_per_visit
        return 0.0 if total_visits.zero?

        (total_pageviews.to_f / total_visits).round(1)
      end

      def total_conversions
        @total_conversions ||= property.conversions
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .count
      end

      def total_revenue
        @total_revenue ||= property.conversions
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .sum(:revenue)
      end

      # Daily breakdown for charts
      def daily_stats
        @daily_stats ||= begin
          dates = date_range.to_a

          visits_by_day = property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .group(Arel.sql("DATE(started_at)"))
            .count

          pageviews_by_day = if use_aggregates?
            property.daily_page_aggregates
              .in_range(date_range.first, date_range.last)
              .group(:date)
              .sum(:pageviews_count)
          else
            property.pageviews
              .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
              .group(Arel.sql("DATE(viewed_at)"))
              .count
          end

          visitors_by_day = property.visits
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .group(Arel.sql("DATE(started_at)"))
            .distinct.count(:visitor_id)

          dates.map do |date|
            {
              date: date,
              visits: visits_by_day[date] || 0,
              pageviews: pageviews_by_day[date] || 0,
              visitors: visitors_by_day[date] || 0
            }
          end
        end
      end

      # Top pages for dashboard widget
      def top_pages(limit: 10)
        if use_aggregates?
          property.daily_page_aggregates
            .in_range(date_range.first, date_range.last)
            .group(:path)
            .select("path, SUM(pageviews_count) as total, SUM(unique_visitors) as visitors")
            .order(Arel.sql("SUM(pageviews_count) DESC"))
            .limit(limit)
        else
          property.pageviews
            .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
            .group(:path)
            .select("path, COUNT(*) as total, COUNT(DISTINCT visitor_id) as visitors")
            .order(Arel.sql("COUNT(*) DESC"))
            .limit(limit)
        end
      end

      # Top referrers for dashboard widget
      def top_referrers(limit: 10)
        property.visits
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .where.not(referrer_host: [nil, ""])
          .group(:referrer_host)
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(limit)
          .pluck(:referrer_host, Arel.sql("COUNT(*)"))
      end

      private

      def csv_headers
        %w[date visits pageviews visitors]
      end

      def csv_rows
        daily_stats.map { |s| [s[:date], s[:visits], s[:pageviews], s[:visitors]] }
      end
    end
  end
end
