# frozen_string_literal: true

module LocalAnalytics
  # Runs daily to roll up raw data into aggregate tables.
  # Schedule this via cron, Sidekiq-Cron, or Solid Queue recurring.
  # Recommended: run once daily after midnight for the previous day.
  #
  #   # Example with Sidekiq-Cron
  #   Sidekiq::Cron::Job.create(name: "la_aggregation", cron: "15 0 * * *",
  #     class: "LocalAnalytics::AggregationJob")
  class AggregationJob < ApplicationJob
    queue_as { LocalAnalytics.configuration.job_queue }

    def perform(date: nil, property_id: nil)
      return unless LocalAnalytics.configuration.aggregation_enabled

      target_date = date ? Date.parse(date.to_s) : Date.yesterday
      properties = property_id ? Property.where(id: property_id) : Property.active

      properties.find_each do |property|
        Services::Aggregator.new(property: property, date: target_date).aggregate_all
        Rails.logger.info("[LocalAnalytics] Aggregated #{property.name} for #{target_date}")
      end
    end
  end
end
