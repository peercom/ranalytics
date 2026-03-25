class CreateLocalAnalyticsTables < ActiveRecord::Migration[8.1]
  def change
    # ── Properties ──────────────────────────────────────────────────
    create_table :local_analytics_properties do |t|
      t.string  :name,              null: false
      t.string  :key,               null: false
      t.string  :timezone,          null: false, default: "UTC"
      t.string  :currency,          default: "USD"
      t.boolean :active,            null: false, default: true
      t.string  :allowed_hostnames, array: true, default: []
      t.integer :retention_days
      t.timestamps
    end
    add_index :local_analytics_properties, :key, unique: true
    add_index :local_analytics_properties, :active

    # ── Visitors ────────────────────────────────────────────────────
    create_table :local_analytics_visitors do |t|
      t.references :property,       null: false, foreign_key: { to_table: :local_analytics_properties }
      t.string     :visitor_token,  null: false
      t.boolean    :returning,      null: false, default: false
      t.datetime   :first_seen_at
      t.timestamps
    end
    add_index :local_analytics_visitors, [:property_id, :visitor_token], unique: true, name: "idx_la_visitors_property_token"

    # ── Visits (Sessions) ───────────────────────────────────────────
    create_table :local_analytics_visits do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.references :visitor,         null: false, foreign_key: { to_table: :local_analytics_visitors }
      t.string     :visit_token,     null: false
      t.datetime   :started_at,      null: false
      t.datetime   :ended_at
      t.boolean    :bounced,         null: false, default: true
      t.string     :ip

      # Referrer
      t.string  :referrer_url
      t.string  :referrer_host
      t.string  :referrer_source
      t.string  :referrer_medium
      t.string  :search_engine
      t.string  :social_network

      # Campaign / UTM
      t.string  :utm_source
      t.string  :utm_medium
      t.string  :utm_campaign
      t.string  :utm_term
      t.string  :utm_content

      # Device
      t.string  :browser
      t.string  :browser_version
      t.string  :os
      t.string  :os_version
      t.string  :device_type
      t.string  :screen_resolution
      t.string  :viewport_size
      t.string  :language

      # Location
      t.string  :country
      t.string  :region
      t.string  :city

      t.timestamps
    end

    # Primary query pattern: property + date range
    add_index :local_analytics_visits, [:property_id, :started_at], name: "idx_la_visits_property_started"
    add_index :local_analytics_visits, [:visitor_id, :property_id, :started_at], name: "idx_la_visits_visitor_property_started"
    add_index :local_analytics_visits, :visit_token
    add_index :local_analytics_visits, [:property_id, :referrer_host], name: "idx_la_visits_referrer"
    add_index :local_analytics_visits, [:property_id, :utm_campaign], name: "idx_la_visits_campaign"
    add_index :local_analytics_visits, [:property_id, :device_type], name: "idx_la_visits_device"
    add_index :local_analytics_visits, [:property_id, :country], name: "idx_la_visits_country"
    add_index :local_analytics_visits, [:property_id, :bounced], name: "idx_la_visits_bounced"

    # ── Pageviews ───────────────────────────────────────────────────
    # Append-heavy table. BRIN index on viewed_at for efficient time-range scans.
    create_table :local_analytics_pageviews do |t|
      t.references :property,       null: false, foreign_key: { to_table: :local_analytics_properties }
      t.references :visit,          null: false, foreign_key: { to_table: :local_analytics_visits }
      t.references :visitor,        null: false, foreign_key: { to_table: :local_analytics_visitors }
      t.string     :url,            null: false
      t.string     :path,           null: false
      t.string     :title
      t.string     :referrer
      t.datetime   :viewed_at,      null: false
      t.string     :query_string
      t.integer    :page_load_time
      t.string     :navigation_type
      t.string     :screen_resolution
      t.string     :viewport_size
      t.string     :language
    end

    add_index :local_analytics_pageviews, [:property_id, :viewed_at], name: "idx_la_pageviews_property_viewed",
              using: :brin
    add_index :local_analytics_pageviews, [:property_id, :path], name: "idx_la_pageviews_property_path"
    # Note: t.references :visit already creates an index on visit_id

    # ── Events ──────────────────────────────────────────────────────
    create_table :local_analytics_events do |t|
      t.references :property,  null: false, foreign_key: { to_table: :local_analytics_properties }
      t.references :visit,     null: false, foreign_key: { to_table: :local_analytics_visits }
      t.references :visitor,   null: false, foreign_key: { to_table: :local_analytics_visitors }
      t.string     :category,  null: false
      t.string     :action,    null: false
      t.string     :name
      t.decimal    :value,     precision: 12, scale: 2
      t.jsonb      :metadata,  default: {}
      t.timestamps
    end

    add_index :local_analytics_events, [:property_id, :created_at], name: "idx_la_events_property_created",
              using: :brin
    add_index :local_analytics_events, [:property_id, :category, :action], name: "idx_la_events_cat_action"

    # ── Goals ───────────────────────────────────────────────────────
    create_table :local_analytics_goals do |t|
      t.references :property,       null: false, foreign_key: { to_table: :local_analytics_properties }
      t.string     :name,           null: false
      t.string     :key,            null: false
      t.string     :goal_type,      null: false
      t.boolean    :active,         null: false, default: true
      t.jsonb      :match_config,   default: {}
      t.decimal    :revenue_default, precision: 12, scale: 2
      t.timestamps
    end
    add_index :local_analytics_goals, [:property_id, :key], unique: true, name: "idx_la_goals_property_key"
    add_index :local_analytics_goals, [:property_id, :active], name: "idx_la_goals_active"

    # ── Conversions ─────────────────────────────────────────────────
    create_table :local_analytics_conversions do |t|
      t.references :property,     null: false, foreign_key: { to_table: :local_analytics_properties }
      t.references :goal,         null: false, foreign_key: { to_table: :local_analytics_goals }
      t.references :visit,        null: false, foreign_key: { to_table: :local_analytics_visits }
      t.references :visitor,      null: false, foreign_key: { to_table: :local_analytics_visitors }
      t.decimal    :revenue,      precision: 12, scale: 2
      t.datetime   :converted_at, null: false
    end
    add_index :local_analytics_conversions, [:goal_id, :visit_id], unique: true, name: "idx_la_conversions_goal_visit"
    add_index :local_analytics_conversions, [:property_id, :converted_at], name: "idx_la_conversions_property_date"

    # ── Daily Page Aggregates ───────────────────────────────────────
    create_table :local_analytics_daily_page_aggregates do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.date       :date,            null: false
      t.string     :path,            null: false
      t.integer    :pageviews_count, null: false, default: 0
      t.integer    :unique_visitors, null: false, default: 0
      t.integer    :visits_count,    null: false, default: 0
      t.integer    :entries,         null: false, default: 0
      t.integer    :exits,           null: false, default: 0
      t.integer    :bounces,         null: false, default: 0
    end
    add_index :local_analytics_daily_page_aggregates,
              [:property_id, :date, :path], unique: true, name: "idx_la_daily_pages_uniq"
    add_index :local_analytics_daily_page_aggregates,
              [:property_id, :date], name: "idx_la_daily_pages_prop_date"

    # ── Daily Referrer Aggregates ───────────────────────────────────
    create_table :local_analytics_daily_referrer_aggregates do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.date       :date,            null: false
      t.string     :referrer_host
      t.string     :referrer_source
      t.string     :referrer_medium
      t.string     :utm_source
      t.string     :utm_medium
      t.string     :utm_campaign
      t.integer    :visits_count,    null: false, default: 0
      t.integer    :unique_visitors, null: false, default: 0
      t.integer    :bounces,         null: false, default: 0
    end
    add_index :local_analytics_daily_referrer_aggregates,
              [:property_id, :date], name: "idx_la_daily_referrers_prop_date"

    # ── Daily Device Aggregates ─────────────────────────────────────
    create_table :local_analytics_daily_device_aggregates do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.date       :date,            null: false
      t.string     :browser
      t.string     :os
      t.string     :device_type
      t.integer    :visits_count,    null: false, default: 0
      t.integer    :unique_visitors, null: false, default: 0
    end
    add_index :local_analytics_daily_device_aggregates,
              [:property_id, :date], name: "idx_la_daily_devices_prop_date"

    # ── Daily Location Aggregates ───────────────────────────────────
    create_table :local_analytics_daily_location_aggregates do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.date       :date,            null: false
      t.string     :country
      t.string     :region
      t.string     :city
      t.integer    :visits_count,    null: false, default: 0
      t.integer    :unique_visitors, null: false, default: 0
    end
    add_index :local_analytics_daily_location_aggregates,
              [:property_id, :date], name: "idx_la_daily_locations_prop_date"

    # ── Daily Event Aggregates ──────────────────────────────────────
    create_table :local_analytics_daily_event_aggregates do |t|
      t.references :property,        null: false, foreign_key: { to_table: :local_analytics_properties }
      t.date       :date,            null: false
      t.string     :category
      t.string     :action
      t.integer    :events_count,    null: false, default: 0
      t.integer    :unique_visitors, null: false, default: 0
      t.decimal    :total_value,     precision: 12, scale: 2, default: 0
    end
    add_index :local_analytics_daily_event_aggregates,
              [:property_id, :date], name: "idx_la_daily_events_prop_date"
  end
end
