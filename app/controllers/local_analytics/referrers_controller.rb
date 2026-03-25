# frozen_string_literal: true

module LocalAnalytics
  class ReferrersController < ApplicationController
    before_action :require_property!

    def index
      @report = Reports::ReferrersReport.new(
        property: current_property,
        date_range: date_range,
        page: params[:page] || 1,
        per_page: 50
      )
    end

    def export
      @report = Reports::ReferrersReport.new(
        property: current_property,
        date_range: date_range,
        page: 1,
        per_page: 10_000
      )

      respond_to do |format|
        format.csv do
          send_data @report.to_csv,
                    filename: "referrers_#{date_range.first}_#{date_range.last}.csv",
                    type: "text/csv"
        end
      end
    end
  end
end
