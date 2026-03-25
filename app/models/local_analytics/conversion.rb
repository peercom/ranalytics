# frozen_string_literal: true

module LocalAnalytics
  # A Conversion records that a Goal was achieved during a Visit.
  class Conversion < ApplicationRecord
    belongs_to :property
    belongs_to :goal
    belongs_to :visit
    belongs_to :visitor

    validates :goal_id, uniqueness: { scope: :visit_id, message: "already converted in this visit" }

    scope :in_range, ->(from, to) { where(converted_at: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }
    scope :for_goal, ->(goal_id) { where(goal_id: goal_id) }

    before_validation :set_converted_at

    private

    def set_converted_at
      self.converted_at ||= Time.current
    end
  end
end
