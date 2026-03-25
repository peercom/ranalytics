# frozen_string_literal: true

module LocalAnalytics
  class ReportSubscriptionsController < ApplicationController
    before_action :require_property!, except: [:index]
    before_action :set_subscription, only: [:show, :edit, :update, :destroy, :send_now]

    def index
      @subscriptions = if current_property
        current_property.report_subscriptions.order(:name)
      else
        ReportSubscription.includes(:property).order(:name)
      end
    end

    def show; end

    def new
      @subscription = current_property.report_subscriptions.build(
        frequency: "weekly",
        report_type: "dashboard",
        day_of_week: "monday",
        hour_of_day: 8,
        active: true
      )
    end

    def create
      @subscription = current_property.report_subscriptions.build(subscription_params)
      if @subscription.save
        redirect_to report_subscriptions_path(property_id: current_property.id),
                    notice: "Report subscription created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to report_subscriptions_path(property_id: current_property.id),
                    notice: "Report subscription updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @subscription.destroy
      redirect_to report_subscriptions_path(property_id: current_property.id),
                  notice: "Subscription deleted."
    end

    def send_now
      EmailReportJob.perform_later(subscription_id: @subscription.id)
      redirect_to report_subscriptions_path(property_id: current_property.id),
                  notice: "Report queued for delivery to #{@subscription.recipients}."
    end

    private

    def set_subscription
      @subscription = ReportSubscription.find(params[:id])
    end

    def subscription_params
      params.require(:report_subscription).permit(
        :name, :recipients, :frequency, :report_type, :active,
        :day_of_week, :day_of_month, :hour_of_day
      )
    end
  end
end
