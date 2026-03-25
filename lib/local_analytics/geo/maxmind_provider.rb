# frozen_string_literal: true

require "maxminddb"

module LocalAnalytics
  module Geo
    # MaxMind GeoLite2/GeoIP2 local database provider.
    # Requires a .mmdb file (download from MaxMind).
    #
    # Usage:
    #   LocalAnalytics.configure do |config|
    #     config.enable_geo = true
    #     config.geo_provider = LocalAnalytics::Geo::MaxMindProvider.new(
    #       database_path: Rails.root.join("db/GeoLite2-City.mmdb")
    #     )
    #   end
    class MaxMindProvider
      def initialize(database_path:)
        @db = MaxMindDB.new(database_path.to_s)
      end

      def lookup(ip)
        return empty_result if ip.blank?

        result = @db.lookup(ip)
        return empty_result unless result&.found?

        {
          country: result.country&.iso_code,
          region: result.subdivisions&.first&.iso_code,
          city: result.city&.name
        }
      rescue => e
        Rails.logger.warn("[LocalAnalytics] MaxMind lookup failed for #{ip}: #{e.message}")
        empty_result
      end

      private

      def empty_result
        { country: nil, region: nil, city: nil }
      end
    end
  end
end
