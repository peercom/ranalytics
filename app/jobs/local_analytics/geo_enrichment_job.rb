# frozen_string_literal: true

module LocalAnalytics
  # Backfills geo data for visits that were recorded without it.
  # Useful when geo is enabled after initial setup, or when using
  # an async geo provider.
  class GeoEnrichmentJob < ApplicationJob
    queue_as { LocalAnalytics.configuration.job_queue }

    def perform(property_id: nil, limit: 1000)
      return unless LocalAnalytics.configuration.enable_geo

      scope = Visit.where(country: [nil, ""]).where.not(ip: [nil, ""])
      scope = scope.where(property_id: property_id) if property_id
      provider = LocalAnalytics.configuration.geo_provider_instance

      scope.limit(limit).find_each do |visit|
        geo = provider.lookup(visit.ip)
        next if geo[:country].blank?

        visit.update_columns(
          country: geo[:country],
          region: geo[:region],
          city: geo[:city]
        )
      end
    end
  end
end
