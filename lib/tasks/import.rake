# frozen_string_literal: true

namespace :local_analytics do
  namespace :import do
    desc "Import data from active_analytics gem into LocalAnalytics"
    task active_analytics: :environment do
      require "local_analytics/importers/active_analytics"

      site = ENV["SITE"]
      property_key = ENV["PROPERTY_KEY"]
      dry_run = ENV["DRY_RUN"] == "true"

      options = { dry_run: dry_run }
      options[:site] = site if site.present?

      if property_key.present?
        property = LocalAnalytics::Property.find_by!(key: property_key)
        options[:property] = property
      end

      puts "Starting ActiveAnalytics import..."
      puts "  Site filter: #{site || 'all'}"
      puts "  Target property: #{property_key || 'auto-create'}"
      puts "  Dry run: #{dry_run}"
      puts ""

      stats = LocalAnalytics::Importers::ActiveAnalytics.import!(**options)

      puts ""
      puts "Done! #{stats}"
    end
  end
end
