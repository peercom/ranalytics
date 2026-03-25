# LocalAnalytics

Self-hosted, privacy-conscious web analytics for Rails applications. A mountable Rails engine that provides comprehensive analytics comparable to Matomo, running entirely inside your Rails app with no external dependencies.

## Features

- **Page view tracking** with entry/exit pages, bounce rate, time on page
- **Sessions & visitors** with new vs. returning visitor classification
- **Referrer analytics** with automatic search engine and social network detection
- **Campaign / UTM tracking** (source, medium, campaign, term, content)
- **Goals & conversions** with configurable matching rules and revenue tracking
- **Custom events** with category/action/name/value and JSONB metadata
- **Site search analytics** from URL query parameters
- **Download & outbound link tracking** (automatic via JS)
- **Device, browser, and OS analytics** via user-agent parsing
- **Geographic analytics** with pluggable IP geolocation (MaxMind adapter included)
- **Real-time dashboard** showing active visitors and recent activity
- **Admin UI** with date-filtered reports, CSV export, and property management
- **Privacy controls**: IP anonymization, DNT respect, consent mode, cookieless mode, bot filtering
- **Configurable data retention** with automated pruning
- **Multi-site support** within one Rails app
- **Background aggregation** into daily rollup tables for fast reporting at scale
- **Turbo/SPA support** with automatic navigation tracking
- **Server-side tracking API** for backend events and conversions
- **No external SaaS dependencies**

## Requirements

- Ruby 3.2+
- Rails 7.1+ or 8.0+
- PostgreSQL
- ActiveJob backend (Sidekiq, Solid Queue, etc.)

## Installation

Add to your Gemfile:

```ruby
gem "local_analytics"
```

Run the install generator:

```bash
bundle install
rails generate local_analytics:install
rails db:migrate
```

This creates:
- `config/initializers/local_analytics.rb` — configuration
- A migration with all analytics tables
- Mounts the engine at `/analytics`

## Quick Start

### 1. Create a property

```ruby
# Via Rails console
LocalAnalytics::Property.create!(
  name: "My Site",
  timezone: "America/New_York"
)
```

Or use the admin UI at `/analytics/properties`.

### 2. Add the tracking tag

In your application layout:

```erb
<%= local_analytics_tracking_tag %>
```

For a specific property:

```erb
<%= local_analytics_tracking_tag(property_key: "your_property_key") %>
```

Optional noscript fallback:

```erb
<%= local_analytics_noscript_tag %>
```

### 3. View your dashboard

Visit `/analytics` in your browser.

## Configuration

All configuration happens in `config/initializers/local_analytics.rb`:

```ruby
LocalAnalytics.configure do |config|
  # Privacy
  config.respect_dnt = true
  config.ip_anonymization = true
  config.consent_required = false
  config.cookieless_mode = false

  # Session
  config.visit_timeout = 30.minutes
  config.cookie_name = "_la_vid"

  # Storage
  config.store_query_parameters = false
  config.retention_period = 24.months

  # Geo (optional)
  config.enable_geo = true
  config.geo_provider = LocalAnalytics::Geo::MaxMindProvider.new(
    database_path: Rails.root.join("db/GeoLite2-City.mmdb")
  )

  # Bot filtering
  config.bot_filtering = true
  config.bot_ignore_ips = ["office.ip.here"]

  # Authentication
  config.authenticate_with = ->(controller) {
    controller.redirect_to("/login") unless controller.send(:current_user)&.admin?
  }

  # Exclude staff from tracking
  config.exclude_user = ->(user) { user.admin? }
end
```

## Authentication

LocalAnalytics does not assume Devise or any specific auth library. Use the `authenticate_with` hook:

```ruby
# Devise
config.authenticate_with = ->(controller) {
  controller.authenticate_admin!
}

# Simple check
config.authenticate_with = ->(controller) {
  unless controller.send(:current_user)&.can_view_analytics?
    controller.redirect_to("/")
  end
}
```

## Tracking

### JavaScript API

The tracking snippet exposes `window.LocalAnalytics`:

```javascript
// Manual pageview
LocalAnalytics.trackPageview({ title: "Custom Title" });

// Custom event
LocalAnalytics.trackEvent("video", "play", {
  name: "intro_video",
  value: 1
});

// Goal conversion
LocalAnalytics.trackGoal("signup", { revenue: 49.0 });

// Consent management
LocalAnalytics.setConsent(true);   // Enable tracking
LocalAnalytics.setConsent(false);  // Disable tracking
```

### Server-Side API

Track events from Ruby code:

```ruby
# Page view
LocalAnalytics.track_pageview(
  property_key: "my_site",
  url: "https://example.com/api/endpoint",
  path: "/api/endpoint",
  visitor_id: "user_123",
  ip: request.remote_ip,
  user_agent: request.user_agent
)

# Custom event
LocalAnalytics.track_event(
  property_key: "my_site",
  category: "purchase",
  action: "completed",
  name: "Premium Plan",
  value: 99.0,
  visitor_id: "user_123"
)

# Goal conversion
LocalAnalytics.track_conversion(
  property_key: "my_site",
  goal_key: "signup",
  visitor_id: "user_123",
  revenue: 49.0
)
```

## Goals

Configure goals in the admin UI or via code:

```ruby
property = LocalAnalytics::Property.find_by(key: "my_site")

# URL match goal
property.goals.create!(
  name: "Thank You Page",
  goal_type: "url_match",
  match_config: { "pattern" => "/thank-you", "match_type" => "exact" }
)

# Event match goal
property.goals.create!(
  name: "Signup Completed",
  goal_type: "event_match",
  match_config: { "category" => "signup", "action" => "completed" }
)

# Time on site goal
property.goals.create!(
  name: "Engaged Visitor",
  goal_type: "time_on_site",
  match_config: { "seconds" => 300 }
)

# Manual goal (triggered via server-side API)
property.goals.create!(
  name: "Purchase",
  goal_type: "manual",
  revenue_default: 29.99
)
```

## Background Jobs

Schedule these jobs in your preferred scheduler:

```ruby
# Daily aggregation (run after midnight)
LocalAnalytics::AggregationJob.perform_later

# Data pruning (run daily or weekly)
LocalAnalytics::PruningJob.perform_later

# Geo enrichment (optional, for backfilling)
LocalAnalytics::GeoEnrichmentJob.perform_later
```

### With Sidekiq-Cron

```ruby
Sidekiq::Cron::Job.create(
  name: "la_aggregation",
  cron: "15 0 * * *",
  class: "LocalAnalytics::AggregationJob"
)

Sidekiq::Cron::Job.create(
  name: "la_pruning",
  cron: "0 3 * * 0",
  class: "LocalAnalytics::PruningJob"
)
```

### With Solid Queue (Rails 8)

```yaml
# config/recurring.yml
la_aggregation:
  class: LocalAnalytics::AggregationJob
  schedule: every day at 12:15am

la_pruning:
  class: LocalAnalytics::PruningJob
  schedule: every sunday at 3am
```

## Multi-Site Support

Create multiple properties for different sites or subdomains:

```ruby
LocalAnalytics::Property.create!(name: "Marketing", timezone: "UTC", allowed_hostnames: ["marketing.example.com"])
LocalAnalytics::Property.create!(name: "App", timezone: "UTC", allowed_hostnames: ["app.example.com"])
```

Auto-detect property from request:

```ruby
config.default_property_finder = ->(request) {
  LocalAnalytics::Property.active.find_by("? = ANY(allowed_hostnames)", request.host)
}
```

## Privacy & Compliance

LocalAnalytics provides technical controls for privacy-conscious analytics:

- **IP anonymization**: Enabled by default. Zeroes the last octet of IPv4 addresses.
- **DNT respect**: Enabled by default. Honors the browser's Do Not Track header.
- **Consent mode**: Set `config.consent_required = true` to require explicit opt-in. Call `LocalAnalytics.setConsent(true)` from JS after user consent.
- **Cookieless mode**: Set `config.cookieless_mode = true` to avoid cookies entirely. Uses a daily-rotating hash for approximate visitor counting.
- **Query parameter stripping**: Disabled by default to avoid capturing sensitive URL parameters.
- **Bot filtering**: Enabled by default.
- **Data retention**: Configurable per-property or globally. Raw data is pruned; aggregates are kept.
- **Visitor deletion**: Delete a visitor's data: `LocalAnalytics::Visitor.find_by(visitor_token: "...").destroy`

## Performance

### Schema Design

- **Append-only raw tables** (pageviews, events) with BRIN indexes for time-range scans
- **Daily aggregate tables** for fast reporting without scanning millions of rows
- **Composite indexes** on (property_id, date) for the primary query pattern
- **JSONB** used sparingly (event metadata, goal match config) — not for hot-path columns

### Scaling Tips

- Run aggregation daily; reports prefer aggregates over raw data
- Configure retention to prune old raw data (aggregates remain)
- For very high traffic, consider PostgreSQL table partitioning on pageviews/events by month
- The tracking endpoint is fire-and-forget (returns 204 immediately, processes async)

## Geolocation

### MaxMind GeoLite2

1. Download GeoLite2-City.mmdb from [MaxMind](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data)
2. Place it in `db/GeoLite2-City.mmdb`
3. Configure:

```ruby
config.enable_geo = true
config.geo_provider = LocalAnalytics::Geo::MaxMindProvider.new(
  database_path: Rails.root.join("db/GeoLite2-City.mmdb")
)
```

### Custom Provider

Implement the provider interface:

```ruby
class MyGeoProvider
  def lookup(ip)
    # Return { country: "US", region: "CA", city: "San Francisco" }
  end
end
```

## Reports & Export

All reports support:
- Date range filtering via `from` and `to` parameters
- Property selection
- CSV export

Available reports:
- Dashboard (overview metrics + daily trend)
- Pages (all pages, entry pages, exit pages)
- Referrers (by source, medium)
- Campaigns (UTM breakdown)
- Goals (conversions, conversion rate, revenue)
- Events (by category/action)
- Devices (device type, browser, OS)
- Locations (country, region, city)
- Site Search (search terms)
- Real-Time (active visitors, recent activity)

## Roadmap

Planned for future versions:

- [ ] Comparison periods (this week vs. last week)
- [ ] Funnel analysis
- [ ] Cohort reports
- [ ] User flow / path analysis
- [ ] Heatmap integration hooks
- [ ] PostgreSQL table partitioning for pageviews/events
- [ ] API endpoints for headless dashboard access
- [ ] Webhook notifications for goal conversions
- [ ] A/B test tracking integration
- [ ] Import from Google Analytics / Matomo
- [ ] Dashboard charts (SVG or lightweight JS charting)
- [ ] Email report scheduling
- [ ] Custom dimensions and metrics
- [ ] Multi-tenant isolation modes
- [ ] Rate limiting on tracking endpoint

## Development

```bash
git clone https://github.com/yourname/local_analytics.git
cd local_analytics
bundle install
# Set up test database
cd spec/dummy && rails db:create db:migrate && cd ../..
bundle exec rspec
```

## License

MIT License. See [MIT-LICENSE](MIT-LICENSE).
