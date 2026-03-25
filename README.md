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
- **Comparison periods** (previous period / same period last year) with delta badges
- **SVG charts** (area, bar, donut, sparkline) — server-rendered, zero JS dependencies
- **Admin UI** with 12 report views, date filtering, CSV export, property management
- **Email report scheduling** — daily/weekly/monthly delivery with CSV attachments
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
- `config/initializers/local_analytics.rb` — full configuration with comments
- A migration creating 14 tables (properties, visitors, visits, pageviews, events, goals, conversions, 5 aggregate tables, report subscriptions)
- Mounts the engine at `/analytics`

## Quick Start

### 1. Create a property

```ruby
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
  # ── Privacy ──────────────────────────────────────────
  config.respect_dnt             = true     # Honor Do Not Track header
  config.ip_anonymization        = true     # Zero last octet of IPv4
  config.store_full_ip           = false    # Don't store raw IPs
  config.store_query_parameters  = false    # Strip query strings from URLs
  config.consent_required        = false    # Require JS consent before tracking
  config.cookieless_mode         = false    # No cookies — daily-rotating hash IDs

  # ── Session ──────────────────────────────────────────
  config.visit_timeout           = 30.minutes
  config.cookie_name             = "_la_vid"
  config.cookie_lifetime         = 13.months

  # ── Data ─────────────────────────────────────────────
  config.retention_period        = 24.months
  config.aggregation_enabled     = true

  # ── Geolocation (optional) ───────────────────────────
  config.enable_geo              = false
  config.geo_provider            = LocalAnalytics::Geo::MaxMindProvider.new(
    database_path: Rails.root.join("db/GeoLite2-City.mmdb")
  )

  # ── Bot filtering ────────────────────────────────────
  config.bot_filtering           = true
  config.bot_ignore_ips          = []       # Exact IPs to ignore
  config.bot_ignore_cidrs        = []       # CIDR ranges to ignore

  # ── Site search ──────────────────────────────────────
  config.site_search_params      = %w[q query search s]

  # ── Downloads / outbound ─────────────────────────────
  config.download_extensions     = %w[pdf zip gz tar rar exe dmg doc docx xls xlsx ppt pptx csv]
  config.track_outbound_links    = true
  config.track_mailto_links      = false

  # ── Authentication ───────────────────────────────────
  config.authenticate_with = ->(controller) {
    controller.redirect_to("/login") unless controller.send(:current_user)&.admin?
  }

  # ── Traffic exclusion ────────────────────────────────
  config.exclude_request = ->(request) { request.path.start_with?("/health") }
  config.exclude_user    = ->(user) { user.admin? }

  # ── Multi-site property resolution ───────────────────
  config.default_property_finder = ->(request) {
    LocalAnalytics::Property.active.find_by("? = ANY(allowed_hostnames)", request.host)
  }

  # ── Email reports ────────────────────────────────────
  config.email_from              = "analytics@example.com"

  # ── Job queue ────────────────────────────────────────
  config.job_queue               = :default
end
```

## Authentication

LocalAnalytics does not assume Devise or any specific auth library. Use the `authenticate_with` hook:

```ruby
# Devise
config.authenticate_with = ->(controller) {
  controller.authenticate_admin!
}

# Custom check
config.authenticate_with = ->(controller) {
  unless controller.send(:current_user)&.can_view_analytics?
    controller.redirect_to("/")
  end
}
```

The tracking endpoint (`/analytics/t`) is always public and does not run authentication.

## Tracking

### JavaScript API

The tracking snippet exposes `window.LocalAnalytics`:

```javascript
// Manual pageview (auto-tracked on load)
LocalAnalytics.trackPageview({ title: "Custom Title" });

// Custom event
LocalAnalytics.trackEvent("video", "play", {
  name: "intro_video",
  value: 1,
  metadata: { duration: 120 }
});

// Goal conversion
LocalAnalytics.trackGoal("signup", { revenue: 49.0 });

// Consent management (when consent_required: true)
LocalAnalytics.setConsent(true);    // Enable tracking after consent
LocalAnalytics.setConsent(false);   // Revoke consent
LocalAnalytics.enableTracking();    // Alias for setConsent(true)
LocalAnalytics.disableTracking();   // Alias for setConsent(false)
```

**Automatic tracking includes:**
- Initial page load
- Turbo Drive navigations (`turbo:load`)
- Browser back/forward (`popstate`)
- Outbound link clicks (configurable)
- File downloads by extension (configurable)
- UTM parameters from URL query strings
- Screen resolution, viewport size, language

### Server-Side API

Track events from Ruby code without the JS tracker:

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

All server-side tracking is async via ActiveJob.

## Goals

Configure goals in the admin UI (`/analytics/goals`) or via code:

```ruby
property = LocalAnalytics::Property.find_by(key: "my_site")

# URL match goal (auto-converts when visitor hits matching page)
property.goals.create!(
  name: "Thank You Page",
  goal_type: "url_match",
  match_config: { "pattern" => "/thank-you", "match_type" => "exact" }
  # match_type options: exact, starts_with, contains, regex
)

# Event match goal (auto-converts when matching event fires)
property.goals.create!(
  name: "Signup Completed",
  goal_type: "event_match",
  match_config: { "category" => "signup", "action" => "completed" }
)

# Time on site goal (auto-converts when visit duration exceeds threshold)
property.goals.create!(
  name: "Engaged Visitor",
  goal_type: "time_on_site",
  match_config: { "seconds" => 300 }
)

# Pages per visit goal
property.goals.create!(
  name: "Deep Explorer",
  goal_type: "pages_per_visit",
  match_config: { "count" => 5 }
)

# Manual goal (triggered via server-side API only)
property.goals.create!(
  name: "Purchase",
  goal_type: "manual",
  revenue_default: 29.99
)
```

## Comparison Periods

All date-filtered reports support comparing against a previous period. Add `?compare=previous` or `?compare=year` to any report URL:

- **Previous period**: same-length range immediately before the current selection (e.g. Mar 1-15 compares against Feb 13-28)
- **Same period last year**: same dates shifted back one year

The dashboard shows percentage-change badges on all 8 metric cards and overlays the previous period as a dashed line on the area chart. Pages and Referrers tables include per-row comparison columns.

The date filter dropdown in the admin UI includes a comparison selector.

## Email Report Scheduling

Schedule automated email reports for any property and report type.

### Setting up via Admin UI

1. Navigate to `/analytics/report_subscriptions`
2. Click "New Subscription"
3. Choose report type, recipients, frequency, and send time
4. Active subscriptions are delivered automatically

### Setting up via code

```ruby
property = LocalAnalytics::Property.find_by(key: "my_site")

# Weekly dashboard every Monday at 8am
property.report_subscriptions.create!(
  name: "Weekly Dashboard for Marketing",
  recipients: "team@example.com, ceo@example.com",
  frequency: "weekly",
  report_type: "dashboard",
  day_of_week: "monday",
  hour_of_day: 8
)

# Daily pages report at 7am
property.report_subscriptions.create!(
  name: "Daily Pages",
  recipients: "seo@example.com",
  frequency: "daily",
  report_type: "pages",
  hour_of_day: 7
)

# Monthly goals report on the 1st at 9am
property.report_subscriptions.create!(
  name: "Monthly Conversions",
  recipients: "analytics@example.com",
  frequency: "monthly",
  report_type: "goals",
  day_of_month: 1,
  hour_of_day: 9
)
```

### Scheduling the delivery job

`EmailReportJob` checks for due subscriptions. Schedule it to run frequently:

```ruby
# Sidekiq-Cron
Sidekiq::Cron::Job.create(
  name: "la_email_reports",
  cron: "*/15 * * * *",
  class: "LocalAnalytics::EmailReportJob"
)
```

```yaml
# Solid Queue (config/recurring.yml)
la_email_reports:
  class: LocalAnalytics::EmailReportJob
  schedule: every 15 minutes
```

### Sending a report immediately

```ruby
# Via admin UI: click "Send Now" on any subscription
# Via code:
LocalAnalytics::EmailReportJob.perform_later(subscription_id: subscription.id)
```

### Email content

- **Dashboard reports**: HTML email with metric cards (visitors, visits, pageviews, bounce rate), top pages table, top referrers table, plus CSV attachment
- **All other reports**: HTML email referencing the attached CSV, plus CSV attachment
- Both HTML and plain text parts are included
- From address configurable via `config.email_from`

### Available report types for scheduling

`dashboard`, `pages`, `referrers`, `campaigns`, `events`, `goals`, `devices`, `locations`, `site_search`

## Background Jobs

| Job | Purpose | Recommended Schedule |
|-----|---------|---------------------|
| `AggregationJob` | Rolls raw data into daily aggregate tables | Daily after midnight |
| `PruningJob` | Deletes raw data beyond retention period | Daily or weekly |
| `GeoEnrichmentJob` | Backfills geo data for visits | As needed |
| `EmailReportJob` | Sends due email report subscriptions | Every 15 minutes |
| `ProcessTrackingJob` | Processes tracking payloads (auto-enqueued) | N/A (triggered automatically) |

### With Sidekiq-Cron

```ruby
Sidekiq::Cron::Job.create(name: "la_aggregation", cron: "15 0 * * *", class: "LocalAnalytics::AggregationJob")
Sidekiq::Cron::Job.create(name: "la_pruning", cron: "0 3 * * 0", class: "LocalAnalytics::PruningJob")
Sidekiq::Cron::Job.create(name: "la_email_reports", cron: "*/15 * * * *", class: "LocalAnalytics::EmailReportJob")
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
la_email_reports:
  class: LocalAnalytics::EmailReportJob
  schedule: every 15 minutes
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

Each property can have its own goals, retention settings, and email subscriptions.

## Admin UI

The admin UI mounts at `/analytics` and includes:

| Report | Charts | Features |
|--------|--------|----------|
| Dashboard | Area (daily trend), sparklines (metric cards), bar (top pages/referrers) | 8 metric cards, comparison deltas, daily breakdown |
| Pages | — | All/entry/exit pages, bounce rates, comparison columns |
| Referrers | Donut (traffic by medium) | Source/medium breakdown, comparison columns |
| Campaigns | — | UTM source/medium/campaign breakdown |
| Goals | — | CRUD, conversion rates, revenue, goal detail with daily chart |
| Events | — | Category/action grouping, category filter |
| Devices | Donut | Device type/browser/OS tabs |
| Locations | Bar | Country/region/city tabs |
| Site Search | — | Search terms with frequency |
| Real-Time | — | Active visitors (5/30 min), recent pageviews/events |
| Email Reports | — | CRUD for subscriptions, send now |
| Properties | — | CRUD with tracking snippet display |

All reports support date range filtering, property switching, CSV export, and comparison periods.

## Privacy & Compliance

LocalAnalytics provides technical controls for privacy-conscious analytics:

| Control | Default | Description |
|---------|---------|-------------|
| IP anonymization | On | Zeroes last octet (IPv4) / last 80 bits (IPv6) |
| DNT respect | On | Honors browser Do Not Track header |
| Consent mode | Off | Suppresses tracking until `LocalAnalytics.setConsent(true)` called |
| Cookieless mode | Off | No cookies; uses daily-rotating IP+UA hash |
| Query stripping | On | Does not store URL query parameters |
| Bot filtering | On | Detects bots via UA patterns + IP/CIDR lists |
| Data retention | 24 months | Configurable per-property; raw data pruned, aggregates kept |
| Visitor deletion | Manual | `LocalAnalytics::Visitor.find_by(visitor_token: "...").destroy` |
| Staff exclusion | Configurable | `config.exclude_user` / `config.exclude_request` |

## Performance & Schema Design

- **14 PostgreSQL tables** with foreign keys and targeted indexes
- **Append-only raw tables** (pageviews, events) with BRIN indexes for time-range scans
- **5 daily aggregate tables** for fast reporting without scanning millions of rows
- **Composite indexes** on (property_id, date) for the primary query pattern
- **JSONB** used sparingly (event metadata, goal match config) — not on hot-path columns
- **Reports auto-detect** whether to use aggregate tables or raw queries based on data availability
- **Tracking endpoint** returns 204 immediately; processing is async via ActiveJob
- **Batch deletion** in pruning job to avoid long-running transactions

### Scaling Tips

- Run `AggregationJob` daily — reports prefer aggregates over raw data when available
- Configure retention to prune old raw data (aggregates are kept indefinitely)
- For very high traffic, consider PostgreSQL table partitioning on pageviews/events by month
- Use a dedicated ActiveJob queue: `config.job_queue = :analytics`

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
    # Must return { country: "US", region: "CA", city: "San Francisco" }
    # Return nils for unknown fields
  end
end
```

## Database Schema

```
local_analytics_properties              — Sites/properties being tracked
local_analytics_visitors                — Unique visitors (cookie-based or cookieless)
local_analytics_visits                  — Sessions with referrer, UTM, device, location data
local_analytics_pageviews               — Individual page views (append-heavy, BRIN-indexed)
local_analytics_events                  — Custom events with JSONB metadata
local_analytics_goals                   — Conversion goal definitions
local_analytics_conversions             — Goal completion records
local_analytics_daily_page_aggregates   — Rolled-up page metrics per day
local_analytics_daily_referrer_aggregates
local_analytics_daily_device_aggregates
local_analytics_daily_location_aggregates
local_analytics_daily_event_aggregates
local_analytics_report_subscriptions    — Scheduled email report configuration
```

## Development

```bash
git clone https://github.com/peercom/local_analytics.git
cd local_analytics
bundle install

# Set up test database (requires PostgreSQL)
createdb local_analytics_test
cd spec/dummy && RAILS_ENV=test rails db:migrate && cd ../..

# Run tests
bundle exec rspec    # 347 examples, 0 failures
```

### Test Coverage

347 specs across 42 spec files covering:
- All 9 models (validations, scopes, associations, business logic)
- All 10 report classes (data queries, CSV export, comparison periods)
- All controllers via request specs (CRUD, export, auth, comparison)
- All 6 jobs (delivery, scheduling, pruning, error handling)
- Both helpers (JS tracker generation, SVG chart rendering)
- All services (tracking processor, aggregator, IP anonymizer, bot detection, server tracker, report builder)
- Mailer (recipients, subject, CSV attachment, HTML/text bodies)
- Authentication integration

## Roadmap

Planned for future versions:

- [x] ~~Comparison periods~~ (shipped in v0.1.0)
- [x] ~~Dashboard charts~~ (shipped in v0.1.0)
- [x] ~~Email report scheduling~~ (shipped in v0.1.0)
- [ ] Funnel analysis
- [ ] Cohort reports
- [ ] User flow / path analysis
- [ ] PostgreSQL table partitioning for pageviews/events
- [ ] API endpoints for headless dashboard access
- [ ] Webhook notifications for goal conversions
- [ ] A/B test tracking integration
- [ ] Import from Google Analytics / Matomo
- [ ] Custom dimensions and metrics
- [ ] Multi-tenant isolation modes
- [ ] Rate limiting on tracking endpoint

## License

MIT License. See [MIT-LICENSE](MIT-LICENSE).
