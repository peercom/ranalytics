# frozen_string_literal: true

module LocalAnalytics
  class DailyReferrerAggregate < ApplicationRecord
    belongs_to :property

    validates :date, presence: true
    validates :date, uniqueness: { scope: [:property_id, :referrer_host, :utm_source, :utm_medium, :utm_campaign] }

    scope :in_range, ->(from, to) { where(date: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }
  end
end
