# frozen_string_literal: true

module LocalAnalytics
  # A Property represents a logical site/property being tracked.
  # Examples: marketing site, app subdomain, docs site.
  class Property < ApplicationRecord
    has_many :visitors, dependent: :destroy
    has_many :visits, dependent: :destroy
    has_many :pageviews, dependent: :destroy
    has_many :events, dependent: :destroy
    has_many :goals, dependent: :destroy
    has_many :conversions, dependent: :destroy
    has_many :daily_page_aggregates, dependent: :destroy
    has_many :daily_referrer_aggregates, dependent: :destroy
    has_many :daily_device_aggregates, dependent: :destroy
    has_many :daily_location_aggregates, dependent: :destroy
    has_many :daily_event_aggregates, dependent: :destroy

    validates :name, presence: true
    validates :key, presence: true, uniqueness: true
    validates :timezone, presence: true

    before_validation :generate_key, on: :create

    scope :active, -> { where(active: true) }

    def allowed_hostname?(hostname)
      return true if allowed_hostnames.blank?

      Array(allowed_hostnames).any? { |h| hostname&.downcase&.end_with?(h.downcase) }
    end

    def effective_retention_period
      retention_days&.days || LocalAnalytics.configuration.retention_period
    end

    private

    def generate_key
      self.key ||= SecureRandom.hex(16)
    end
  end
end
