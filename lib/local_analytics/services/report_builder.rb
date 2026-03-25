# frozen_string_literal: true

module LocalAnalytics
  module Services
    # Builds a report instance for a given subscription.
    # Returns the report object which responds to #to_csv and has data methods.
    class ReportBuilder
      REPORT_MAP = {
        "dashboard"   => "LocalAnalytics::Reports::DashboardReport",
        "pages"       => "LocalAnalytics::Reports::PagesReport",
        "referrers"   => "LocalAnalytics::Reports::ReferrersReport",
        "campaigns"   => "LocalAnalytics::Reports::CampaignsReport",
        "events"      => "LocalAnalytics::Reports::EventsReport",
        "goals"       => "LocalAnalytics::Reports::GoalsReport",
        "devices"     => "LocalAnalytics::Reports::DevicesReport",
        "locations"   => "LocalAnalytics::Reports::LocationsReport",
        "site_search" => "LocalAnalytics::Reports::SiteSearchReport"
      }.freeze

      def initialize(subscription)
        @subscription = subscription
      end

      def build
        klass = REPORT_MAP[@subscription.report_type]
        raise ArgumentError, "Unknown report type: #{@subscription.report_type}" unless klass

        klass.constantize.new(
          property: @subscription.property,
          date_range: @subscription.report_date_range
        )
      end

      def report_title
        "#{@subscription.property.name} — #{@subscription.report_type.titleize} Report"
      end

      def period_label
        range = @subscription.report_date_range
        "#{range.first} to #{range.last}"
      end
    end
  end
end
