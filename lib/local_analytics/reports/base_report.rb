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

      # Prefer aggregate tables for date ranges that are fully in the past.
      # Fall back to raw tables for today or if aggregates haven't run yet.
      def use_aggregates?
        date_range.last < Date.current
      end

      def use_aggregates_for_comparison?
        comparison_range && comparison_range.last < Date.current
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
