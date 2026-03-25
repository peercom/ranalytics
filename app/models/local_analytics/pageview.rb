# frozen_string_literal: true

module LocalAnalytics
  # A Pageview records a single page load or Turbo navigation.
  # This is the primary raw data table and will be append-heavy.
  class Pageview < ApplicationRecord
    belongs_to :property
    belongs_to :visit
    belongs_to :visitor

    validates :url, presence: true
    validates :path, presence: true

    scope :in_range, ->(from, to) { where(viewed_at: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }

    before_validation :set_viewed_at

    def entry_page?
      visit.pageviews.order(:viewed_at).first&.id == id
    end

    def exit_page?
      visit.pageviews.order(:viewed_at).last&.id == id
    end

    private

    def set_viewed_at
      self.viewed_at ||= Time.current
    end
  end
end
