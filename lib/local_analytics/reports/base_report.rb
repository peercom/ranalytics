# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class BaseReport
      attr_reader :property, :date_range, :comparison_range

      def initialize(property:, date_range: nil, comparison_range: nil, **options)
        @property = property
        @date_range = date_range || (30.days.ago.to_date..Date.current)
        @comparison_range = comparison_range
        @options = options
      end

      def comparing?
        comparison_range.present?
      end

      def to_csv
        CSV.generate do |csv|
          csv << csv_headers
          csv_rows.each { |row| csv << row }
        end
      end

      private

      def csv_headers
        raise NotImplementedError
      end

      def csv_rows
        raise NotImplementedError
      end

      def page
        (@options[:page] || 1).to_i
      end

      def per_page
        (@options[:per_page] || 50).to_i
      end

      def offset
        (page - 1) * per_page
      end

      # Prefer aggregate tables for date ranges that are fully in the past
      # AND where aggregates actually exist. Falls back to raw tables otherwise.
      def use_aggregates?
        return false unless date_range.last < Date.current

        property.daily_page_aggregates.in_range(date_range.first, date_range.last).exists?
      end

      def use_aggregates_for_comparison?
        return false unless comparison_range && comparison_range.last < Date.current

        # Only use aggregates if they actually exist for this property/range
        property.daily_page_aggregates.in_range(comparison_range.first, comparison_range.last).exists?
      end

      # Compute percentage change between two values.
      # Returns nil when previous is zero (avoid division by zero).
      def pct_change(current, previous)
        return nil if previous.nil? || previous.zero?

        ((current.to_f - previous.to_f) / previous.to_f * 100).round(1)
      end
    end
  end
end
