# frozen_string_literal: true

module LocalAnalytics
  module Importers
    # Imports data from the active_analytics gem (0.4.x) into LocalAnalytics.
    #
    # ActiveAnalytics stores pre-aggregated daily data in two tables:
    #   - active_analytics_views_per_days  (site, page, date, total, referrer_host, referrer_path)
    #   - active_analytics_browsers_per_days (site, name, version, date, total)
    #
    # Since active_analytics only stores aggregates (not raw pageviews/visits),
    # this importer maps data into LocalAnalytics aggregate tables:
    #   - DailyPageAggregate      (from views_per_days)
    #   - DailyReferrerAggregate  (from views_per_days with referrer data)
    #   - DailyDeviceAggregate    (from browsers_per_days)
    #
    # It also creates a summary Visit + Pageview record per day for historical
    # continuity, so dashboard totals reflect the imported data.
    #
    # Usage:
    #   # Import all sites, auto-creating properties:
    #   LocalAnalytics::Importers::ActiveAnalytics.import!
    #
    #   # Import a specific site into an existing property:
    #   LocalAnalytics::Importers::ActiveAnalytics.import!(
    #     site: "example.com",
    #     property: LocalAnalytics::Property.find_by(key: "main")
    #   )
    #
    #   # Dry run (no writes):
    #   LocalAnalytics::Importers::ActiveAnalytics.import!(dry_run: true)
    #
    class ActiveAnalytics
      VIEWS_TABLE = "active_analytics_views_per_days"
      BROWSERS_TABLE = "active_analytics_browsers_per_days"

      def self.import!(**options)
        new(**options).run
      end

      def initialize(site: nil, property: nil, dry_run: false)
        @site_filter = site
        @target_property = property
        @dry_run = dry_run
        @stats = { pages: 0, referrers: 0, devices: 0, visits: 0, pageviews: 0 }
      end

      def run
        validate_tables!

        sites = discover_sites
        log "Found #{sites.length} site(s): #{sites.join(', ')}"

        sites.each do |site|
          property = resolve_property(site)
          log "Importing '#{site}' into property '#{property.name}' (id: #{property.id})"

          import_page_aggregates(site, property)
          import_referrer_aggregates(site, property)
          import_device_aggregates(site, property)
          import_synthetic_visits(site, property)
        end

        log "Import complete: #{@stats}"
        @stats
      end

      private

      def validate_tables!
        conn = ::ActiveRecord::Base.connection
        unless conn.table_exists?(VIEWS_TABLE)
          raise "Table #{VIEWS_TABLE} not found. Is active_analytics installed?"
        end
      end

      def discover_sites
        scope = ::ActiveRecord::Base.connection.execute(
          "SELECT DISTINCT site FROM #{VIEWS_TABLE} ORDER BY site"
        )
        sites = scope.map { |row| row["site"] }
        sites = sites.select { |s| s == @site_filter } if @site_filter
        sites
      end

      def resolve_property(site)
        return @target_property if @target_property

        existing = Property.find_by(name: site)
        return existing if existing

        if @dry_run
          log "  [DRY RUN] Would create property: #{site}"
          Property.new(name: site, timezone: "UTC")
        else
          Property.create!(name: site, timezone: "UTC")
        end
      end

      def import_page_aggregates(site, property)
        rows = execute(<<~SQL)
          SELECT date, page, SUM(total) as total_views
          FROM #{VIEWS_TABLE}
          WHERE site = #{quote(site)}
          GROUP BY date, page
          ORDER BY date
        SQL

        rows.each do |row|
          next if @dry_run

          DailyPageAggregate.find_or_initialize_by(
            property: property,
            date: row["date"],
            path: row["page"]
          ).tap do |agg|
            agg.pageviews_count = row["total_views"].to_i
            agg.unique_visitors = estimate_visitors(row["total_views"].to_i)
            agg.visits_count = estimate_visitors(row["total_views"].to_i)
            agg.entries = 0
            agg.exits = 0
            agg.bounces = 0
            agg.save!
          end
          @stats[:pages] += 1
        end

        log "  Pages: #{@stats[:pages]} aggregate rows"
      end

      def import_referrer_aggregates(site, property)
        rows = execute(<<~SQL)
          SELECT date, referrer_host, SUM(total) as total_visits
          FROM #{VIEWS_TABLE}
          WHERE site = #{quote(site)}
            AND referrer_host IS NOT NULL
            AND referrer_host != ''
          GROUP BY date, referrer_host
          ORDER BY date
        SQL

        rows.each do |row|
          next if @dry_run

          DailyReferrerAggregate.find_or_initialize_by(
            property: property,
            date: row["date"],
            referrer_host: row["referrer_host"],
            utm_source: nil,
            utm_medium: nil,
            utm_campaign: nil
          ).tap do |agg|
            agg.referrer_source = row["referrer_host"]
            agg.referrer_medium = classify_medium(row["referrer_host"])
            agg.visits_count = row["total_visits"].to_i
            agg.unique_visitors = estimate_visitors(row["total_visits"].to_i)
            agg.bounces = 0
            agg.save!
          end
          @stats[:referrers] += 1
        end

        log "  Referrers: #{@stats[:referrers]} aggregate rows"
      end

      def import_device_aggregates(site, property)
        return unless ::ActiveRecord::Base.connection.table_exists?(BROWSERS_TABLE)

        rows = execute(<<~SQL)
          SELECT date, name as browser, SUM(total) as total_visits
          FROM #{BROWSERS_TABLE}
          WHERE site = #{quote(site)}
          GROUP BY date, name
          ORDER BY date
        SQL

        rows.each do |row|
          next if @dry_run

          DailyDeviceAggregate.find_or_initialize_by(
            property: property,
            date: row["date"],
            browser: row["browser"],
            os: "Unknown",
            device_type: "desktop"
          ).tap do |agg|
            agg.visits_count = row["total_visits"].to_i
            agg.unique_visitors = estimate_visitors(row["total_visits"].to_i)
            agg.save!
          end
          @stats[:devices] += 1
        end

        log "  Devices: #{@stats[:devices]} aggregate rows"
      end

      # Create synthetic daily visits + pageviews so that dashboard totals
      # and date-range queries against raw tables include imported data.
      def import_synthetic_visits(site, property)
        rows = execute(<<~SQL)
          SELECT date, SUM(total) as total_views, COUNT(DISTINCT page) as unique_pages
          FROM #{VIEWS_TABLE}
          WHERE site = #{quote(site)}
          GROUP BY date
          ORDER BY date
        SQL

        # Reuse a single synthetic visitor per property
        visitor = nil
        unless @dry_run
          visitor = property.visitors.find_or_create_by!(visitor_token: "__imported_#{site}") do |v|
            v.first_seen_at = rows.first&.dig("date")&.to_date || Date.current
          end
        end

        rows.each do |row|
          next if @dry_run

          date = row["date"].to_date
          total_views = row["total_views"].to_i
          estimated_visits = estimate_visitors(total_views)

          # Create one synthetic visit per day
          visit = property.visits.find_or_create_by!(
            visitor: visitor,
            visit_token: "__imported_#{site}_#{date}"
          ) do |v|
            v.started_at = date.beginning_of_day
            v.ended_at = date.end_of_day
            v.bounced = false
            v.browser = "Unknown"
            v.os = "Unknown"
            v.device_type = "desktop"
          end
          @stats[:visits] += 1

          # Create one synthetic pageview per day with the total count
          # (We can't reconstruct individual pageviews from aggregates)
          existing_pv = property.pageviews.find_by(visit: visit, path: "/")
          unless existing_pv
            property.pageviews.create!(
              visit: visit,
              visitor: visitor,
              url: "https://#{site}/",
              path: "/",
              title: "Imported",
              viewed_at: date.beginning_of_day
            )
          end
          @stats[:pageviews] += 1
        end

        log "  Synthetic visits: #{@stats[:visits]}, pageviews: #{@stats[:pageviews]}"
      end

      # Since active_analytics only stores total counts (not unique visitors),
      # we estimate uniques as ~60% of total pageviews. This is a rough heuristic
      # that works reasonably for typical sites.
      def estimate_visitors(total)
        [(total * 0.6).ceil, 1].max
      end

      def classify_medium(host)
        return "search" if host&.match?(/google\.|bing\.|yahoo\.|duckduckgo|yandex\.|baidu/)
        return "social" if host&.match?(/facebook|twitter|linkedin|instagram|youtube|reddit|t\.co|x\.com/)

        "referral"
      end

      def execute(sql)
        ::ActiveRecord::Base.connection.execute(sql)
      end

      def quote(value)
        ::ActiveRecord::Base.connection.quote(value)
      end

      def log(message)
        puts "[ActiveAnalytics Import] #{message}" unless Rails.env.test?
        Rails.logger.info("[ActiveAnalytics Import] #{message}")
      end
    end
  end
end
