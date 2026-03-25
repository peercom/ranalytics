# frozen_string_literal: true

FactoryBot.define do
  factory :property, class: "LocalAnalytics::Property" do
    name { "Test Site" }
    timezone { "UTC" }
    currency { "USD" }
    active { true }
    allowed_hostnames { [] }
  end

  factory :visitor, class: "LocalAnalytics::Visitor" do
    property
    visitor_token { SecureRandom.hex(16) }
    returning { false }
    first_seen_at { Time.current }
  end

  factory :visit, class: "LocalAnalytics::Visit" do
    property
    visitor
    visit_token { SecureRandom.hex(16) }
    started_at { Time.current }
    ended_at { Time.current + 5.minutes }
    bounced { false }
    browser { "Chrome" }
    os { "macOS" }
    device_type { "desktop" }
    language { "en" }
  end

  factory :pageview, class: "LocalAnalytics::Pageview" do
    property
    visit
    visitor
    url { "https://example.com/test" }
    path { "/test" }
    title { "Test Page" }
    viewed_at { Time.current }
    navigation_type { "full" }
  end

  factory :event, class: "LocalAnalytics::Event" do
    property
    visit
    visitor
    category { "click" }
    action { "button" }
    name { "signup" }
  end

  factory :goal, class: "LocalAnalytics::Goal" do
    property
    name { "Test Goal" }
    sequence(:key) { |n| "test_goal_#{n}" }
    goal_type { "manual" }
    active { true }
    match_config { {} }
  end

  factory :conversion, class: "LocalAnalytics::Conversion" do
    property
    goal
    visit
    visitor
    revenue { 10.0 }
    converted_at { Time.current }
  end
end
