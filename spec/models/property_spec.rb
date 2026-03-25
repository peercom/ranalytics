# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::Property, type: :model do
  subject(:property) { build(:property) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a name" do
      property.name = nil
      expect(property).not_to be_valid
    end

    it "requires a timezone" do
      property.timezone = nil
      expect(property).not_to be_valid
    end

    it "generates a key on create" do
      property.key = nil
      property.save!
      expect(property.key).to be_present
      expect(property.key.length).to eq(32)
    end

    it "enforces key uniqueness" do
      create(:property, key: "unique_key")
      dup = build(:property, key: "unique_key")
      expect(dup).not_to be_valid
    end
  end

  describe "#allowed_hostname?" do
    it "returns true when no hostnames configured" do
      property.allowed_hostnames = []
      expect(property.allowed_hostname?("anything.com")).to be true
    end

    it "matches configured hostnames" do
      property.allowed_hostnames = ["example.com"]
      expect(property.allowed_hostname?("example.com")).to be true
      expect(property.allowed_hostname?("www.example.com")).to be true
      expect(property.allowed_hostname?("evil.com")).to be false
    end
  end

  describe "#effective_retention_period" do
    it "uses property override when set" do
      property.retention_days = 365
      expect(property.effective_retention_period).to eq(365.days)
    end

    it "falls back to global config" do
      property.retention_days = nil
      expect(property.effective_retention_period).to eq(LocalAnalytics.configuration.retention_period)
    end
  end
end
