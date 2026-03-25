# frozen_string_literal: true

module LocalAnalytics
  module Services
    # Rolls up raw pageviews, events, and visits into daily aggregate tables.
    # This is called by AggregationJob, typically once per day for the previous day.
    # Aggregates enable fast report queries without scanning millions of raw rows.
    class Aggregator
      def initialize(property:, date:)
        @property = property
        @date = date
        @day_range = date.beginning_of_day..date.end_of_day
      end

      def aggregate_all
        ActiveRecord::Base.transaction do
          aggregate_pages
          aggregate_referrers
          aggregate_devices
          aggregate_locations
          aggregate_events
        end
      end

      private

      def aggregate_pages
        # Delete existing aggregates for this date (idempotent re-run)
        @property.daily_page_aggregates.where(date: @date).delete_all

        rows = @property.pageviews
          .where(viewed_at: @day_range)
          .group(:path)
          .pluck(
            :path,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT local_analytics_pageviews.visitor_id)"),
            Arel.sql("COUNT(DISTINCT local_analytics_pageviews.visit_id)")
          )

        # Compute entry/exit pages
        entry_pages = entry_page_counts
        exit_pages = exit_page_counts
        bounce_counts = bounce_page_counts

        rows.each do |path, pageviews_count, unique_visitors, visits|
          DailyPageAggregate.create!(
            property: @property,
            date: @date,
            path: path,
            pageviews_count: pageviews_count,
            unique_visitors: unique_visitors,
            visits_count: visits,
            entries: entry_pages[path] || 0,
            exits: exit_pages[path] || 0,
            bounces: bounce_counts[path] || 0
          )
        end
      end

      def entry_page_counts
        # Entry page = first pageview of each visit
        sql = <<~SQL
          SELECT pv.path, COUNT(*) as entries
          FROM local_analytics_pageviews pv
          INNER JOIN (
            SELECT visit_id, MIN(viewed_at) as first_at
            FROM local_analytics_pageviews
            WHERE property_id = #{@property.id}
              AND viewed_at BETWEEN '#{@day_range.first.iso8601}' AND '#{@day_range.last.iso8601}'
            GROUP BY visit_id
          ) first_pv ON pv.visit_id = first_pv.visit_id AND pv.viewed_at = first_pv.first_at
          WHERE pv.property_id = #{@property.id}
          GROUP BY pv.path
        SQL
        ActiveRecord::Base.connection.execute(sql).each_with_object({}) do |row, hash|
          hash[row["path"]] = row["entries"].to_i
        end
      end

      def exit_page_counts
        sql = <<~SQL
          SELECT pv.path, COUNT(*) as exits
          FROM local_analytics_pageviews pv
          INNER JOIN (
            SELECT visit_id, MAX(viewed_at) as last_at
            FROM local_analytics_pageviews
            WHERE property_id = #{@property.id}
              AND viewed_at BETWEEN '#{@day_range.first.iso8601}' AND '#{@day_range.last.iso8601}'
            GROUP BY visit_id
          ) last_pv ON pv.visit_id = last_pv.visit_id AND pv.viewed_at = last_pv.last_at
          WHERE pv.property_id = #{@property.id}
          GROUP BY pv.path
        SQL
        ActiveRecord::Base.connection.execute(sql).each_with_object({}) do |row, hash|
          hash[row["path"]] = row["exits"].to_i
        end
      end

      def bounce_page_counts
        sql = <<~SQL
          SELECT pv.path, COUNT(*) as bounces
          FROM local_analytics_pageviews pv
          INNER JOIN local_analytics_visits v ON v.id = pv.visit_id
          INNER JOIN (
            SELECT visit_id, MIN(viewed_at) as first_at
            FROM local_analytics_pageviews
            WHERE property_id = #{@property.id}
              AND viewed_at BETWEEN '#{@day_range.first.iso8601}' AND '#{@day_range.last.iso8601}'
            GROUP BY visit_id
          ) first_pv ON pv.visit_id = first_pv.visit_id AND pv.viewed_at = first_pv.first_at
          WHERE pv.property_id = #{@property.id}
            AND v.bounced = true
          GROUP BY pv.path
        SQL
        ActiveRecord::Base.connection.execute(sql).each_with_object({}) do |row, hash|
          hash[row["path"]] = row["bounces"].to_i
        end
      end

      def aggregate_referrers
        @property.daily_referrer_aggregates.where(date: @date).delete_all

        @property.visits
          .where(started_at: @day_range)
          .group(:referrer_host, :utm_source, :utm_medium, :utm_campaign, :referrer_source, :referrer_medium)
          .pluck(
            :referrer_host, :utm_source, :utm_medium, :utm_campaign,
            :referrer_source, :referrer_medium,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT visitor_id)"),
            Arel.sql("SUM(CASE WHEN bounced THEN 1 ELSE 0 END)")
          ).each do |host, src, med, camp, ref_src, ref_med, visits, visitors, bounces|
            DailyReferrerAggregate.create!(
              property: @property,
              date: @date,
              referrer_host: host,
              utm_source: src,
              utm_medium: med,
              utm_campaign: camp,
              referrer_source: ref_src,
              referrer_medium: ref_med,
              visits_count: visits,
              unique_visitors: visitors,
              bounces: bounces
            )
          end
      end

      def aggregate_devices
        @property.daily_device_aggregates.where(date: @date).delete_all

        @property.visits
          .where(started_at: @day_range)
          .group(:browser, :os, :device_type)
          .pluck(
            :browser, :os, :device_type,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT visitor_id)")
          ).each do |browser, os, device_type, visits, visitors|
            DailyDeviceAggregate.create!(
              property: @property,
              date: @date,
              browser: browser,
              os: os,
              device_type: device_type,
              visits_count: visits,
              unique_visitors: visitors
            )
          end
      end

      def aggregate_locations
        @property.daily_location_aggregates.where(date: @date).delete_all

        @property.visits
          .where(started_at: @day_range)
          .where.not(country: [nil, ""])
          .group(:country, :region, :city)
          .pluck(
            :country, :region, :city,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT visitor_id)")
          ).each do |country, region, city, visits, visitors|
            DailyLocationAggregate.create!(
              property: @property,
              date: @date,
              country: country,
              region: region,
              city: city,
              visits_count: visits,
              unique_visitors: visitors
            )
          end
      end

      def aggregate_events
        @property.daily_event_aggregates.where(date: @date).delete_all

        @property.events
          .where(created_at: @day_range)
          .group(:category, :action)
          .pluck(
            :category, :action,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT local_analytics_events.visitor_id)"),
            Arel.sql("SUM(COALESCE(value, 0))")
          ).each do |category, action, count, visitors, total_value|
            DailyEventAggregate.create!(
              property: @property,
              date: @date,
              category: category,
              action: action,
              events_count: count,
              unique_visitors: visitors,
              total_value: total_value
            )
          end
      end
    end
  end
end
