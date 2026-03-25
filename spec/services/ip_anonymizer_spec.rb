# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Services::IpAnonymizer do
  describe ".anonymize" do
    it "zeroes last octet for IPv4" do
      expect(described_class.anonymize("192.168.1.100")).to eq("192.168.1.0")
    end

    it "zeroes last 80 bits for IPv6" do
      result = described_class.anonymize("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
      expect(result).to eq("2001:db8:85a3::")
    end

    it "returns nil for blank input" do
      expect(described_class.anonymize(nil)).to be_nil
      expect(described_class.anonymize("")).to be_nil
    end

    it "returns nil for invalid IP" do
      expect(described_class.anonymize("not_an_ip")).to be_nil
    end
  end
end
