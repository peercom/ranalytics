# frozen_string_literal: true

module LocalAnalytics
  module Reports
    class GoalsReport < BaseReport
      def rows
        @rows ||= property.goals.active.map do |goal|
          conversions = goal.conversions.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          total_visits = property.visits.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day).count

          OpenStruct.new(
            goal: goal,
            conversions_count: conversions.count,
            conversion_rate: total_visits > 0 ? (conversions.count.to_f / total_visits * 100).round(1) : 0.0,
            revenue: conversions.sum(:revenue)
          )
        end
      end

      private

      def csv_headers
        %w[goal_name conversions conversion_rate revenue]
      end

      def csv_rows
        rows.map { |r| [r.goal.name, r.conversions_count, r.conversion_rate, r.revenue] }
      end
    end

    class GoalDetailReport < BaseReport
      attr_reader :goal

      def initialize(property:, goal:, date_range: nil, **options)
        super(property: property, date_range: date_range, **options)
        @goal = goal
      end

      def total_conversions
        @total_conversions ||= goal.conversions
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .count
      end

      def conversion_rate
        total_visits = property.visits.in_range(date_range.first.beginning_of_day, date_range.last.end_of_day).count
        return 0.0 if total_visits.zero?

        (total_conversions.to_f / total_visits * 100).round(1)
      end

      def total_revenue
        @total_revenue ||= goal.conversions
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .sum(:revenue)
      end

      def daily_conversions
        goal.conversions
          .in_range(date_range.first.beginning_of_day, date_range.last.end_of_day)
          .group(Arel.sql("DATE(converted_at)"))
          .count
      end

      private

      def csv_headers
        %w[date conversions]
      end

      def csv_rows
        daily_conversions.sort.map { |date, count| [date, count] }
      end
    end
  end
end
