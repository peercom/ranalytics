# frozen_string_literal: true

module LocalAnalytics
  class Configuration
    # ── Cookie / Visitor ────────────────────────────────────────────
    attr_accessor :cookie_name, :cookie_lifetime, :cookieless_mode

    # ── Session / Visit ─────────────────────────────────────────────
    attr_accessor :visit_timeout

    # ── Privacy ─────────────────────────────────────────────────────
    attr_accessor :respect_dnt, :ip_anonymization, :store_full_ip,
                  :store_query_parameters, :consent_required

    # ── Geo ─────────────────────────────────────────────────────────
    attr_accessor :enable_geo, :geo_provider

    # ── Bot filtering ───────────────────────────────────────────────
    attr_accessor :bot_filtering, :bot_ignore_ips, :bot_ignore_cidrs

    # ── Data retention ──────────────────────────────────────────────
    attr_accessor :retention_period, :aggregation_enabled

    # ── Site search ─────────────────────────────────────────────────
    attr_accessor :site_search_params

    # ── Downloads / outbound ────────────────────────────────────────
    attr_accessor :download_extensions, :track_outbound_links, :track_mailto_links

    # ── Auth / Authorization ────────────────────────────────────────
    attr_accessor :authenticate_with, :authorize_with, :current_user_method

    # ── Traffic exclusion ───────────────────────────────────────────
    attr_accessor :exclude_request, :exclude_user

    # ── Property resolution ─────────────────────────────────────────
    attr_accessor :default_property_finder

    # ── Tracker ─────────────────────────────────────────────────────
    attr_accessor :tracker_endpoint_path

    # ── Queue name for ActiveJob ────────────────────────────────────
    attr_accessor :job_queue

    def initialize
      @cookie_name             = "_la_vid"
      @cookie_lifetime         = 13.months
      @cookieless_mode         = false
      @visit_timeout           = 30.minutes
      @respect_dnt             = true
      @ip_anonymization        = true
      @store_full_ip           = false
      @store_query_parameters  = false
      @consent_required        = false
      @enable_geo              = false
      @geo_provider            = nil # lazy-loaded to NullProvider
      @bot_filtering           = true
      @bot_ignore_ips          = []
      @bot_ignore_cidrs        = []
      @retention_period        = 24.months
      @aggregation_enabled     = true
      @site_search_params      = %w[q query search s]
      @download_extensions     = %w[pdf zip gz tar rar exe dmg doc docx xls xlsx ppt pptx csv]
      @track_outbound_links    = true
      @track_mailto_links      = false
      @authenticate_with       = nil
      @authorize_with          = nil
      @current_user_method     = :current_user
      @exclude_request         = ->(_request) { false }
      @exclude_user            = ->(_user) { false }
      @default_property_finder = nil
      @tracker_endpoint_path   = "/t"
      @job_queue               = :default
    end

    def geo_provider_instance
      @geo_provider || Geo::NullProvider.new
    end
  end
end
