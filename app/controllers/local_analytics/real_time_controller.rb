# frozen_string_literal: true

module LocalAnalytics
  class RealTimeController < ApplicationController
    before_action :require_property!

    def show
      @report = Reports::RealTimeReport.new(
        property: current_property
      )
    end
  end
end
