# frozen_string_literal: true

module LocalAnalytics
  class ReportMailer < ApplicationMailer
    def scheduled_report(subscription_id)
      @subscription = ReportSubscription.find(subscription_id)
      builder = Services::ReportBuilder.new(@subscription)
      @report = builder.build
      @title = builder.report_title
      @period = builder.period_label
      @property = @subscription.property

      csv_data = @report.to_csv
      filename = "#{@subscription.report_type}_#{@subscription.report_date_range.first}_#{@subscription.report_date_range.last}.csv"

      attachments[filename] = {
        mime_type: "text/csv",
        content: csv_data
      }

      from_address = LocalAnalytics.configuration.email_from || "analytics@example.com"

      mail(
        to: @subscription.recipient_list,
        from: from_address,
        subject: "[Analytics] #{@title} — #{@period}"
      )
    end
  end
end
