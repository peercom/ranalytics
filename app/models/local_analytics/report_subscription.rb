# frozen_string_literal: true

module LocalAnalytics
  # A ReportSubscription defines a scheduled email report delivery.
  # Each subscription sends a specific report type to one or more recipients
  # on a configurable schedule (daily, weekly, monthly).
  class ReportSubscription < ApplicationRecord
    belongs_to :property

    FREQUENCIES = %w[daily weekly monthly].freeze
    REPORT_TYPES = %w[dashboard pages referrers campaigns events goals devices locations site_search].freeze
    DAYS_OF_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

    validates :name, presence: true
    validates :recipients, presence: true
    validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
    validates :report_type, presence: true, inclusion: { in: REPORT_TYPES }
    validates :day_of_week, inclusion: { in: DAYS_OF_WEEK }, allow_nil: true
    validates :day_of_month, numericality: { in: 1..28, allow_nil: true }
    validate :schedule_consistency

    scope :active, -> { where(active: true) }
    scope :due, -> { active.where("next_send_at <= ?", Time.current) }

    before_validation :compute_next_send_at, if: -> { next_send_at.blank? }
    after_save :recompute_next_send_at!, if: :saved_change_to_frequency?

    # Returns parsed recipient list (comma-separated string -> array).
    def recipient_list
      recipients.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    # Advances next_send_at to the next scheduled time after delivery.
    def advance_schedule!
      self.last_sent_at = Time.current
      self.next_send_at = compute_next_occurrence(from: Time.current)
      save!
    end

    # Computes the date range this report should cover based on frequency.
    def report_date_range
      case frequency
      when "daily"
        yesterday = Date.yesterday
        yesterday..yesterday
      when "weekly"
        end_date = Date.yesterday
        start_date = end_date - 6.days
        start_date..end_date
      when "monthly"
        end_date = Date.yesterday
        start_date = end_date.beginning_of_month
        start_date..end_date
      end
    end

    private

    def schedule_consistency
      if frequency == "weekly" && day_of_week.blank?
        errors.add(:day_of_week, "is required for weekly subscriptions")
      end
      if frequency == "monthly" && day_of_month.blank?
        errors.add(:day_of_month, "is required for monthly subscriptions")
      end
    end

    def compute_next_send_at
      self.next_send_at = compute_next_occurrence(from: Time.current)
    end

    def recompute_next_send_at!
      update_column(:next_send_at, compute_next_occurrence(from: Time.current))
    end

    def compute_next_occurrence(from:)
      tz = ActiveSupport::TimeZone[property&.timezone || "UTC"]
      now = from.in_time_zone(tz)
      send_hour = (hour_of_day || 8)

      case frequency
      when "daily"
        target = now.change(hour: send_hour, min: 0)
        target += 1.day if target <= now
        target
      when "weekly"
        dow_index = DAYS_OF_WEEK.index(day_of_week) || 0
        target = now.beginning_of_week(:monday) + dow_index.days
        target = target.change(hour: send_hour, min: 0)
        target += 1.week if target <= now
        target
      when "monthly"
        dom = [day_of_month || 1, 28].min
        target = now.change(day: dom, hour: send_hour, min: 0)
        target += 1.month if target <= now
        target
      end
    end
  end
end
