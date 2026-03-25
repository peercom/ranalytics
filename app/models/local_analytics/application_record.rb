# frozen_string_literal: true

module LocalAnalytics
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "local_analytics_"
  end
end
