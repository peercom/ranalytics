# frozen_string_literal: true

module LocalAnalytics
  class DevicesController < ApplicationController
    before_action :require_property!

    def index
      @report = Reports::DevicesReport.new(
        property: current_property,
        date_range: date_range,
        dimension: params[:dimension] || "device_type" # device_type, browser, os
      )
    end

    def export
      @report = Reports::DevicesReport.new(
        property: current_property,
        date_range: date_range,
        dimension: params[:dimension] || "device_type"
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "devices_#{params[:dimension] || 'device_type'}_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
