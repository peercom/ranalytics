# frozen_string_literal: true

module LocalAnalytics
  # A Visit (session) groups pageviews and events within a timeout window.
  # A new visit begins when the visitor returns after visit_timeout has elapsed
  # or when the referrer/campaign changes.
  class Visit < ApplicationRecord
    belongs_to :property
    belongs_to :visitor
    has_many :pageviews, dependent: :destroy
    has_many :events, dependent: :destroy
    has_many :conversions, dependent: :destroy

    validates :visit_token, presence: true

    scope :bounced, -> { where(bounced: true) }
    scope :not_bounced, -> { where(bounced: false) }
    scope :in_range, ->(from, to) { where(started_at: from..to) }
    scope :for_property, ->(property_id) { where(property_id: property_id) }

    # Referrer fields
    # referrer_url, referrer_host, referrer_source, referrer_medium
    # search_engine, social_network

    # Campaign fields (UTM)
    # utm_source, utm_medium, utm_campaign, utm_term, utm_content

    # Device fields
    # browser, browser_version, os, os_version, device_type
    # screen_resolution, viewport_size, language

    # Location fields
    # country, region, city, ip (anonymized)

    def duration
      return 0 unless ended_at && started_at

      (ended_at - started_at).to_i
    end

    def update_bounce_status!
      update_column(:bounced, pageviews.count <= 1)
    end

    def touch_ended_at!(time = Time.current)
      update_column(:ended_at, time)
    end
  end
end
