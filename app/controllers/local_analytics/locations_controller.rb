# frozen_string_literal: true

module LocalAnalytics
  class LocationsController < ApplicationController
    before_action :require_property!

    def index
      @report = Reports::LocationsReport.new(
        property: current_property,
        date_range: date_range,
        dimension: params[:dimension] || "country" # country, region, city
      )
    end

    def export
      @report = Reports::LocationsReport.new(
        property: current_property,
        date_range: date_range,
        dimension: params[:dimension] || "country"
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "locations_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
