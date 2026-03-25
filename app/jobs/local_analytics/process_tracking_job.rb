# frozen_string_literal: true

module LocalAnalytics
  class ProcessTrackingJob < ApplicationJob
    queue_as { LocalAnalytics.configuration.job_queue }

    # Discard payloads that fail repeatedly — tracking data is append-only
    # and it's better to lose a record than retry forever.
    discard_on StandardError do |job, error|
      Rails.logger.error("[LocalAnalytics] Discarding tracking job: #{error.message}")
    end

    def perform(payload)
      Services::TrackingProcessor.new(payload).process
    end
  end
end
