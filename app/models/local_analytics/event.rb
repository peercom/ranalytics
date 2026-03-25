# frozen_string_literal: true

module LocalAnalytics
  # An Event records a custom user action (click, download, form submit, etc.).
  class Event < ApplicationRecord
    belongs_to :property
    belongs_to :visit
    belongs_to :visitor

    validates :category, presence: true
    validates :action, presence: true

    scope :in_range, ->(from, to) { where(created_at: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }
  end
end
