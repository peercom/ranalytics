# frozen_string_literal: true

module LocalAnalytics
  # A Goal defines a conversion target for a property.
  # Goal types:
  #   - url_match: visitor hits a specific URL pattern
  #   - event_match: a specific event category/action fires
  #   - time_on_site: visit duration exceeds threshold
  #   - pages_per_visit: pageview count exceeds threshold
  #   - manual: conversion recorded via server-side API
  class Goal < ApplicationRecord
    belongs_to :property
    has_many :conversions, dependent: :destroy

    GOAL_TYPES = %w[url_match event_match time_on_site pages_per_visit manual].freeze

    validates :name, presence: true
    validates :goal_type, presence: true, inclusion: { in: GOAL_TYPES }
    validates :key, presence: true, uniqueness: { scope: :property_id }

    scope :active, -> { where(active: true) }

    before_validation :generate_key, on: :create

    # match_config is a JSONB column storing type-specific matching rules:
    #   url_match:       { "pattern" => "/thank-you*", "match_type" => "starts_with" }
    #   event_match:     { "category" => "signup", "action" => "completed" }
    #   time_on_site:    { "seconds" => 300 }
    #   pages_per_visit: { "count" => 5 }
    #   manual:          {} (no auto-matching)

    def matches_pageview?(pageview)
      return false unless active? && goal_type == "url_match"

      pattern = match_config&.dig("pattern")
      return false if pattern.blank?

      case match_config&.dig("match_type")
      when "exact"
        pageview.path == pattern
      when "starts_with"
        pageview.path&.start_with?(pattern.chomp("*"))
      when "contains"
        pageview.path&.include?(pattern)
      when "regex"
        Regexp.new(pattern).match?(pageview.path)
      else
        pageview.path == pattern
      end
    rescue RegexpError
      false
    end

    def matches_event?(event)
      return false unless active? && goal_type == "event_match"

      ec = match_config&.dig("category")
      ea = match_config&.dig("action")
      (ec.blank? || event.category == ec) && (ea.blank? || event.action == ea)
    end

    def matches_visit_duration?(seconds)
      return false unless active? && goal_type == "time_on_site"

      threshold = match_config&.dig("seconds").to_i
      threshold > 0 && seconds >= threshold
    end

    def matches_pages_per_visit?(count)
      return false unless active? && goal_type == "pages_per_visit"

      threshold = match_config&.dig("count").to_i
      threshold > 0 && count >= threshold
    end

    private

    def generate_key
      self.key ||= name&.parameterize(separator: "_")
    end
  end
end
