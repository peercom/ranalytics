# frozen_string_literal: true

module LocalAnalytics
  # Finds all due report subscriptions and sends them.
  # Schedule this to run frequently (e.g. every 15 minutes or hourly).
  #
  #   # Sidekiq-Cron
  #   Sidekiq::Cron::Job.create(name: "la_email_reports", cron: "*/15 * * * *",
  #     class: "LocalAnalytics::EmailReportJob")
  #
  #   # Solid Queue
  #   la_email_reports:
  #     class: LocalAnalytics::EmailReportJob
  #     schedule: every 15 minutes
  class EmailReportJob < ApplicationJob
    queue_as { LocalAnalytics.configuration.job_queue }

    def perform(subscription_id: nil)
      if subscription_id
        send_report(ReportSubscription.find(subscription_id))
      else
        ReportSubscription.due.find_each do |subscription|
          send_report(subscription)
        end
      end
    end

    private

    def send_report(subscription)
      ReportMailer.scheduled_report(subscription.id).deliver_now
      subscription.advance_schedule!
      Rails.logger.info("[LocalAnalytics] Sent #{subscription.report_type} report to #{subscription.recipients}")
    rescue => e
      Rails.logger.error("[LocalAnalytics] Email report failed for subscription #{subscription.id}: #{e.message}")
    end
  end
end
