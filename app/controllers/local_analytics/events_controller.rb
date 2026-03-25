# frozen_string_literal: true

module LocalAnalytics
  class EventsController < ApplicationController
    before_action :require_property!

    def index
      @report = Reports::EventsReport.new(
        property: current_property,
        date_range: date_range,
        page: params[:page] || 1,
        per_page: 50,
        category_filter: params[:category]
      )
    end

    def export
      @report = Reports::EventsReport.new(
        property: current_property,
        date_range: date_range,
        page: 1,
        per_page: 10_000,
        category_filter: params[:category]
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "events_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
