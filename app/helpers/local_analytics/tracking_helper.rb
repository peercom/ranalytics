# frozen_string_literal: true

module LocalAnalytics
  module TrackingHelper
    # Renders the tracking JavaScript snippet in the host app layout.
    #
    # Usage in layout:
    #   <%= local_analytics_tracking_tag(property_key: "your_key") %>
    #
    # Or with auto-detection:
    #   <%= local_analytics_tracking_tag %>
    def local_analytics_tracking_tag(property_key: nil, options: {})
      config = LocalAnalytics.configuration

      # Resolve property key
      key = property_key
      if key.blank? && config.default_property_finder
        prop = config.default_property_finder.call(request)
        key = prop.is_a?(String) ? prop : prop&.key
      end
      key ||= LocalAnalytics::Property.active.first&.key

      return "".html_safe if key.blank?

      # Check if we should skip this request
      if config.exclude_request.call(request)
        return "".html_safe
      end

      # Check user exclusion
      if respond_to?(config.current_user_method, true)
        user = send(config.current_user_method)
        if user && config.exclude_user.call(user)
          return "".html_safe
        end
      end

      tracker_url = local_analytics.tracking_create_url
      consent_required = config.consent_required || options[:consent_required]

      tag.script(
        local_analytics_inline_js(key, tracker_url, consent_required, config),
        nonce: content_security_policy_nonce
      )
    end

    # Outputs the noscript pixel fallback for when JS is disabled.
    def local_analytics_noscript_tag(property_key: nil)
      key = property_key || LocalAnalytics::Property.active.first&.key
      return "".html_safe if key.blank?

      pixel_url = local_analytics.tracking_pixel_url(pk: key, u: "", p: "", t: "")
      tag.noscript do
        tag.img(src: pixel_url, style: "border:0", alt: "", width: 1, height: 1)
      end
    end

    private

    def local_analytics_inline_js(key, tracker_url, consent_required, config)
      <<~JS.html_safe
        (function() {
          if (typeof window.LocalAnalytics !== 'undefined') return;

          var LA = window.LocalAnalytics = {
            propertyKey: #{key.to_json},
            endpoint: #{tracker_url.to_json},
            consentRequired: #{!!consent_required},
            consentGiven: #{!consent_required},
            cookieName: #{config.cookie_name.to_json},
            cookieless: #{!!config.cookieless_mode},
            trackOutbound: #{!!config.track_outbound_links},
            downloadExtensions: #{config.download_extensions.to_json},

            getVisitorId: function() {
              if (this.cookieless) return null;
              var vid = this.getCookie(this.cookieName);
              if (!vid) {
                vid = this.generateId();
                this.setCookie(this.cookieName, vid, #{config.cookie_lifetime.to_i / 86400});
              }
              return vid;
            },

            generateId: function() {
              return 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'.replace(/x/g, function() {
                return (Math.random() * 16 | 0).toString(16);
              });
            },

            getCookie: function(name) {
              var match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
              return match ? match[2] : null;
            },

            setCookie: function(name, value, days) {
              var d = new Date();
              d.setTime(d.getTime() + days * 86400000);
              document.cookie = name + '=' + value + ';path=/;expires=' + d.toUTCString() + ';SameSite=Lax';
            },

            send: function(payload) {
              if (this.consentRequired && !this.consentGiven) return;
              payload.property_key = this.propertyKey;
              payload.visitor_id = this.getVisitorId();
              payload.url = window.location.href;
              payload.referrer = document.referrer;
              payload.screen_resolution = screen.width + 'x' + screen.height;
              payload.viewport_size = window.innerWidth + 'x' + window.innerHeight;
              payload.language = navigator.language;

              // UTM params from URL
              var params = new URLSearchParams(window.location.search);
              ['utm_source','utm_medium','utm_campaign','utm_term','utm_content'].forEach(function(p) {
                if (params.get(p)) payload[p] = params.get(p);
              });

              var blob = new Blob([JSON.stringify(payload)], {type: 'application/json'});
              if (navigator.sendBeacon) {
                navigator.sendBeacon(this.endpoint, blob);
              } else {
                var xhr = new XMLHttpRequest();
                xhr.open('POST', this.endpoint, true);
                xhr.setRequestHeader('Content-Type', 'application/json');
                xhr.send(JSON.stringify(payload));
              }
            },

            trackPageview: function(opts) {
              opts = opts || {};
              this.send(Object.assign({
                type: 'pageview',
                path: window.location.pathname,
                title: document.title,
                nav_type: opts.navType || 'full'
              }, opts));
            },

            trackEvent: function(category, action, opts) {
              opts = opts || {};
              this.send(Object.assign({
                type: 'event',
                category: category,
                action: action,
                name: opts.name || opts.label,
                value: opts.value,
                metadata: opts.metadata
              }, opts));
            },

            trackGoal: function(goalKey, opts) {
              opts = opts || {};
              this.send(Object.assign({
                type: 'conversion',
                goal_key: goalKey,
                revenue: opts.revenue
              }, opts));
            },

            enableTracking: function() { this.consentGiven = true; },
            disableTracking: function() { this.consentGiven = false; },
            setConsent: function(v) { this.consentGiven = !!v; }
          };

          // Auto-track initial page view
          LA.trackPageview();

          // Turbo Drive support: track navigations
          document.addEventListener('turbo:load', function() {
            LA.trackPageview({ navType: 'turbo' });
          });

          // Popstate for SPA-like back/forward
          window.addEventListener('popstate', function() {
            LA.trackPageview({ navType: 'popstate' });
          });

          // Outbound link and download tracking
          if (LA.trackOutbound || LA.downloadExtensions.length > 0) {
            document.addEventListener('click', function(e) {
              var link = e.target.closest('a');
              if (!link || !link.href) return;

              try {
                var url = new URL(link.href);

                // Outbound link
                if (LA.trackOutbound && url.hostname !== window.location.hostname) {
                  LA.trackEvent('outbound', 'click', { name: url.href });
                }

                // Download
                var ext = url.pathname.split('.').pop().toLowerCase();
                if (LA.downloadExtensions.indexOf(ext) !== -1) {
                  LA.trackEvent('download', ext, { name: url.pathname });
                }
              } catch(err) {}
            }, true);
          }
        })();
      JS
    end
  end
end
