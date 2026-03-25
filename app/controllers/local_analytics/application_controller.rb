# frozen_string_literal: true

module LocalAnalytics
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    helper LocalAnalytics::ChartHelper

    before_action :authenticate_admin!
    before_action :set_current_property

    helper_method :current_property, :available_properties, :date_range

    private

    def authenticate_admin!
      auth = LocalAnalytics.configuration.authenticate_with
      return unless auth

      instance_exec(&auth)
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

    def require_property!
      head :not_found unless current_property
    end
  end
end
