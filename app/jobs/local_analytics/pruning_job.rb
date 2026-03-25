# frozen_string_literal: true

module LocalAnalytics
  # Deletes raw analytics data older than the retention period.
  # Aggregate tables are kept longer since they're compact.
  # Schedule this daily or weekly.
  class PruningJob < ApplicationJob
    queue_as { LocalAnalytics.configuration.job_queue }

    def perform
      Property.find_each do |property|
        cutoff = property.effective_retention_period.ago

        # Delete in batches to avoid long-running transactions
        deleted_pageviews = delete_in_batches(Pageview.where(property: property).where("viewed_at < ?", cutoff))
        deleted_events = delete_in_batches(Event.where(property: property).where("created_at < ?", cutoff))
        deleted_visits = delete_in_batches(Visit.where(property: property).where("started_at < ?", cutoff))

        # Prune orphaned visitors (no remaining visits)
        deleted_visitors = Visitor.where(property: property)
          .where.not(id: Visit.where(property: property).select(:visitor_id))
          .delete_all

        Rails.logger.info(
          "[LocalAnalytics] Pruned #{property.name}: " \
          "#{deleted_pageviews} pageviews, #{deleted_events} events, " \
          "#{deleted_visits} visits, #{deleted_visitors} visitors"
        )
      end
    end

    private

    def delete_in_batches(scope, batch_size: 10_000)
      total = 0
      loop do
        deleted = scope.limit(batch_size).delete_all
        total += deleted
        break if deleted < batch_size
      end
      total
    end
  end
end
