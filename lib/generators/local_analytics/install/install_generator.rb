# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module LocalAnalytics
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs LocalAnalytics: creates initializer, migration, and mounts routes."

      def copy_initializer
        template "initializer.rb", "config/initializers/local_analytics.rb"
      end

      def copy_migration
        migration_template "create_local_analytics_tables.rb.erb",
                           "db/migrate/create_local_analytics_tables.rb"
      end

      def mount_engine
        route 'mount LocalAnalytics::Engine, at: "/analytics"'
      end

      def show_readme
        say ""
        say "LocalAnalytics installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Review config/initializers/local_analytics.rb"
        say "  2. Run: rails db:migrate"
        say "  3. Create a property in the admin UI or via console:"
        say '     LocalAnalytics::Property.create!(name: "My Site", timezone: "UTC")'
        say "  4. Add the tracking tag to your layout:"
        say '     <%= local_analytics_tracking_tag %>'
        say "  5. Visit /analytics to see your dashboard"
        say ""
      end

      private

      def migration_version
        "[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
