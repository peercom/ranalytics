# frozen_string_literal: true

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_job.queue_adapter = :test
  config.action_controller.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  if config.respond_to?(:active_record)
    config.active_record.migration_error = :page_load
  end
end
