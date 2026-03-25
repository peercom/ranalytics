# frozen_string_literal: true

LocalAnalytics.configure do |config|
  config.authenticate_with = nil
  config.respect_dnt = true
  config.ip_anonymization = true
end
