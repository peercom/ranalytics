# frozen_string_literal: true

module LocalAnalytics
  class PagesController < ApplicationController
    before_action :require_property!

    def index
      @report = Reports::PagesReport.new(
        property: current_property,
        date_range: date_range,
        page: params[:page] || 1,
        per_page: 50,
        report_type: params[:type] || "all" # all, entry, exit
      )
    end

    def export
      @report = Reports::PagesReport.new(
        property: current_property,
        date_range: date_range,
        page: 1,
        per_page: 10_000,
        report_type: params[:type] || "all"
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "pages_#{params[:type] || 'all'}_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
