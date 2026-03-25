# Changelog

## 0.1.0 (Unreleased)

### Core Analytics
- Page view, session, and visitor tracking
- Referrer and campaign (UTM) analytics with automatic source classification
- Custom event tracking with category/action/name/value + JSONB metadata
- Goals and conversions with 5 goal types (url_match, event_match, time_on_site, pages_per_visit, manual)
- Site search analytics from configurable URL query parameters
- Download and outbound link tracking (automatic via JS)
- Device, browser, and OS analytics via user-agent parsing
- Pluggable geolocation with MaxMind adapter
- Real-time dashboard (active visitors, recent pageviews/events)

### Admin UI
- 12 report views: dashboard, pages (all/entry/exit), referrers, campaigns, goals, events, devices, locations, site search, real-time, email subscriptions, properties
- SVG charts: area (daily trends), bar (top items), donut (breakdowns), sparklines (metric cards) — server-rendered, zero JS dependencies
- Comparison periods: previous period / same period last year with percentage-change delta badges and dashed chart overlays
- Date range filtering, property switching, CSV export on all reports
- Goal CRUD and property management

### Email Reports
- ReportSubscription model for scheduled email delivery
- Daily, weekly, and monthly frequencies with timezone-aware scheduling
- 9 report types available for scheduling
- HTML + text multipart emails with CSV attachments
- Dashboard emails include inline metric summaries
- Admin UI for subscription management with "Send Now" button
- EmailReportJob processes due subscriptions automatically

### Tracking
- Inline JS tracker via `<%= local_analytics_tracking_tag %>` (no build tools)
- Turbo Drive and SPA navigation auto-tracking
- Noscript pixel fallback
- Server-side Ruby API: `LocalAnalytics.track_pageview/event/conversion`
- Fire-and-forget tracking endpoint (204 + async ActiveJob)

### Privacy
- IP anonymization (last octet zeroing, enabled by default)
- Do Not Track header respect
- Consent mode (suppress tracking until explicit opt-in)
- Cookieless mode (daily-rotating IP+UA hash)
- Query parameter stripping
- Bot filtering (UA patterns + IP/CIDR blocklists)
- User/request exclusion hooks
- Configurable data retention with automated pruning

### Infrastructure
- Mountable Rails engine for Rails 7.1+ / 8.0+
- PostgreSQL-first with 14 tables, BRIN indexes, composite indexes
- 5 daily aggregate tables for fast reporting at scale
- 6 background jobs (tracking, aggregation, pruning, geo enrichment, email reports)
- Install generator with migration, initializer, and route mounting
- Multi-site support within one Rails app
- 347 automated tests with comprehensive coverage
