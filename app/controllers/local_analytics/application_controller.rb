# frozen_string_literal: true

module LocalAnalytics
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    helper LocalAnalytics::ChartHelper

    before_action :authenticate_admin!
    before_action :set_current_property

    helper_method :current_property, :available_properties, :date_range, :comparison_range, :comparing?

    private

    def authenticate_admin!
      auth = LocalAnalytics.configuration.authenticate_with
      return unless auth

      instance_exec(self, &auth)
    end

    def set_current_property
      @current_property = if params[:property_id].present?
        Property.find_by(id: params[:property_id])
      else
        Property.active.first
      end
    end

    def current_property
      @current_property
    end

    def available_properties
      @available_properties ||= Property.active.order(:name)
    end

    def date_range
      @date_range ||= begin
        from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
        to = params[:to].present? ? Date.parse(params[:to]) : Date.current
        from..to
      rescue Date::Error
        30.days.ago.to_date..Date.current
      end
    end

    # Compute the comparison date range based on the `compare` param.
    # Modes:
    #   "previous" — same-length period immediately before the current range
    #   "year"     — same dates one year earlier
    #   nil        — no comparison
    def comparison_range
      @comparison_range ||= begin
        mode = params[:compare]
        return nil if mode.blank?

        days = (date_range.last - date_range.first).to_i + 1

        case mode
        when "previous"
          prev_end = date_range.first - 1.day
          prev_start = prev_end - (days - 1).days
          prev_start..prev_end
        when "year"
          (date_range.first.prev_year)..(date_range.last.prev_year)
        end
      end
    end

    def comparing?
      comparison_range.present?
    end

    def require_property!
      head :not_found unless current_property
    end
  end
end
