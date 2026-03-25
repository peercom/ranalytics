# frozen_string_literal: true

module LocalAnalytics
  class DashboardController < ApplicationController
    before_action :require_property!

    def show
      @report = Reports::DashboardReport.new(
        property: current_property,
        date_range: date_range
      )
    end

    def export
      @report = Reports::DashboardReport.new(
        property: current_property,
        date_range: date_range
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "dashboard_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
