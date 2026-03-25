# frozen_string_literal: true

require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)
require "local_analytics"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_record.migration_error = :page_load
    config.secret_key_base = "test_secret_key_base_for_local_analytics_dummy_app_12345678901234567890"
  end
end
