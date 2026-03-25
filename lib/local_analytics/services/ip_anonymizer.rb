# frozen_string_literal: true

require "ipaddr"

module LocalAnalytics
  module Services
    # Anonymizes IP addresses by zeroing the last octet (IPv4) or last 80 bits (IPv6).
    # This is the same approach used by Google Analytics and Matomo.
    class IpAnonymizer
      def self.anonymize(ip_string)
        return nil if ip_string.blank?

        addr = IPAddr.new(ip_string)
        if addr.ipv4?
          # Zero last octet: 192.168.1.100 -> 192.168.1.0
          addr.mask(24).to_s
        else
          # Zero last 80 bits for IPv6
          addr.mask(48).to_s
        end
      rescue IPAddr::InvalidAddressError
        nil
      end
    end
  end
end
