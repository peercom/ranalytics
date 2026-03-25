# frozen_string_literal: true

module LocalAnalytics
  # A Visitor is a unique browser/device identified by a first-party cookie
  # or fingerprint in cookieless mode. One visitor may have many visits over time.
  class Visitor < ApplicationRecord
    belongs_to :property
    has_many :visits, dependent: :destroy
    has_many :pageviews, through: :visits
    has_many :events, through: :visits
    has_many :conversions, through: :visits

    validates :visitor_token, presence: true
    validates :visitor_token, uniqueness: { scope: :property_id }

    scope :returning, -> { where(returning: true) }
    scope :new_visitors, -> { where(returning: false) }

    def mark_returning!
      update_column(:returning, true) unless returning?
    end
  end
end
