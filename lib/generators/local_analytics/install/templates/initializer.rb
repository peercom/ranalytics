# frozen_string_literal: true

LocalAnalytics.configure do |config|
  # ── Cookie / Visitor ────────────────────────────────────────────────
  # Name of the first-party cookie used to identify visitors.
  # config.cookie_name = "_la_vid"

  # How long the visitor cookie persists.
  # config.cookie_lifetime = 13.months

  # Enable cookieless mode. Reduces fidelity but avoids cookies entirely.
  # Visitors are identified by a daily-rotating hash of IP + User-Agent.
  # config.cookieless_mode = false

  # ── Session / Visit ─────────────────────────────────────────────────
  # Inactivity timeout before starting a new visit/session.
  # config.visit_timeout = 30.minutes

  # ── Privacy ─────────────────────────────────────────────────────────
  # Respect the browser's Do Not Track header.
  # config.respect_dnt = true

  # Anonymize IP addresses by zeroing the last octet (IPv4) or last 80 bits (IPv6).
  # config.ip_anonymization = true

  # Store the full (non-anonymized) IP address. Not recommended unless needed for geo.
  # config.store_full_ip = false

  # Store URL query parameters. Disable to avoid capturing sensitive data in URLs.
  # config.store_query_parameters = false

  # Require explicit consent before tracking. When true, the JS tracker
  # will not send data until LocalAnalytics.setConsent(true) is called.
  # config.consent_required = false

  # ── Geolocation ─────────────────────────────────────────────────────
  # Enable IP-based geolocation. Requires a geo provider.
  # config.enable_geo = false

  # Geo provider instance. Ships with NullProvider (no-op) and MaxMindProvider.
  # config.geo_provider = LocalAnalytics::Geo::MaxMindProvider.new(
  #   database_path: Rails.root.join("db/GeoLite2-City.mmdb")
  # )

  # ── Bot Filtering ───────────────────────────────────────────────────
  # Automatically filter known bots, crawlers, and headless browsers.
  # config.bot_filtering = true

  # IPs to always ignore (e.g., your office IP).
  # config.bot_ignore_ips = ["203.0.113.50"]

  # CIDR ranges to always ignore.
  # config.bot_ignore_cidrs = ["10.0.0.0/8"]

  # ── Data Retention ──────────────────────────────────────────────────
  # How long to keep raw analytics data. Aggregates are kept indefinitely.
  # config.retention_period = 24.months

  # Enable background aggregation jobs.
  # config.aggregation_enabled = true

  # ── Site Search ─────────────────────────────────────────────────────
  # URL query parameter names that indicate a site search.
  # config.site_search_params = %w[q query search s]

  # ── Downloads / Outbound Links ──────────────────────────────────────
  # File extensions to track as downloads.
  # config.download_extensions = %w[pdf zip gz tar rar exe dmg doc docx xls xlsx ppt pptx csv]

  # Automatically track clicks to external domains.
  # config.track_outbound_links = true

  # Track mailto: link clicks.
  # config.track_mailto_links = false

  # ── Authentication / Authorization ──────────────────────────────────
  # Protect the analytics admin UI. This lambda runs as a before_action.
  # config.authenticate_with = ->(controller) {
  #   controller.redirect_to("/login") unless controller.send(:current_user)&.admin?
  # }

  # Optional authorization check (runs after authentication).
  # config.authorize_with = ->(controller) {
  #   controller.head(:forbidden) unless controller.send(:current_user)&.can_view_analytics?
  # }

  # Method name on the host app controller that returns the current user.
  # config.current_user_method = :current_user

  # ── Traffic Exclusion ───────────────────────────────────────────────
  # Exclude specific requests from tracking (e.g., health checks).
  # config.exclude_request = ->(request) {
  #   request.path.start_with?("/health")
  # }

  # Exclude specific users from tracking (e.g., admin/staff).
  # config.exclude_user = ->(user) {
  #   user.respond_to?(:admin?) && user.admin?
  # }

  # ── Property Resolution ─────────────────────────────────────────────
  # Auto-detect the property from the request. Useful for multi-site setups.
  # config.default_property_finder = ->(request) {
  #   LocalAnalytics::Property.active.find_by("? = ANY(allowed_hostnames)", request.host)
  # }

  # ── Job Queue ───────────────────────────────────────────────────────
  # ActiveJob queue name for all LocalAnalytics jobs.
  # config.job_queue = :default
end
