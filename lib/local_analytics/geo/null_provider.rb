# frozen_string_literal: true

module LocalAnalytics
  module Geo
    # Default no-op geo provider. Returns empty results.
    # Replace with MaxMindProvider or a custom provider.
    class NullProvider
      def lookup(_ip)
        { country: nil, region: nil, city: nil }
      end
    end
  end
end
