# frozen_string_literal: true

module LocalAnalytics
  class VisitorProfilesController < ApplicationController
    before_action :require_property!

    # Single visitor's full history.
    def show
      @visitor = current_property.visitors.find(params[:id])

      @visits = @visitor.visits
        .where(property: current_property)
        .includes(:pageviews, :events, :conversions)
        .order(started_at: :desc)

      @total_visits = @visits.count
      @total_pageviews = @visitor.pageviews.joins(:visit).where(local_analytics_visits: { property_id: current_property.id }).count
      @total_events = @visitor.events.joins(:visit).where(local_analytics_visits: { property_id: current_property.id }).count
      @total_conversions = @visitor.conversions.joins(:visit).where(local_analytics_visits: { property_id: current_property.id }).count
      @first_seen = @visits.minimum(:started_at)
      @last_seen = @visits.maximum(:started_at)
    end
  end
end
