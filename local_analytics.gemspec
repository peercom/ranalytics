# frozen_string_literal: true

require_relative "lib/local_analytics/version"

Gem::Specification.new do |spec|
  spec.name        = "local_analytics"
  spec.version     = LocalAnalytics::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["you@example.com"]
  spec.homepage    = "https://github.com/yourname/local_analytics"
  spec.summary     = "Self-hosted, privacy-conscious web analytics for Rails"
  spec.description = "A mountable Rails engine providing comprehensive web analytics: " \
                     "page views, sessions, visitors, referrers, campaigns, goals, events, " \
                     "device/browser/geo analytics, real-time dashboards, and more. " \
                     "Runs entirely inside your Rails app with no external dependencies."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails",        ">= 7.1", "< 9.0"
  spec.add_dependency "pg",           ">= 1.4"
  spec.add_dependency "device_detector", "~> 1.1"
  spec.add_dependency "browser",      "~> 6.0"
  spec.add_dependency "maxminddb",    "~> 0.1"
  spec.add_dependency "ipaddr"
  spec.add_dependency "csv"

  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.0"
  spec.add_development_dependency "shoulda-matchers", "~> 6.0"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
end
