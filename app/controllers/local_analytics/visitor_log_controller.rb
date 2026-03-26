# frozen_string_literal: true

module LocalAnalytics
  class VisitorLogController < ApplicationController
    before_action :require_property!

    PER_PAGE = 30

    # Paginated list of recent visits with session details.
    def index
      @page = [params[:page].to_i, 1].max
      base = current_property.visits
        .includes(:visitor, :pageviews, :events, :conversions)
        .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
        .order(started_at: :desc)

      @total_count = base.count
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @visits = base.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
    end
  end
end
