# frozen_string_literal: true

module LocalAnalytics
  # Pre-computed daily page-level metrics. Built by AggregationJob.
  # Reports should query this table instead of raw pageviews for date ranges.
  class DailyPageAggregate < ApplicationRecord
    belongs_to :property

    validates :date, presence: true
    validates :path, presence: true
    validates :date, uniqueness: { scope: [:property_id, :path] }

    scope :in_range, ->(from, to) { where(date: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }
  end
end
