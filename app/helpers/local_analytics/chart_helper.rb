# frozen_string_literal: true

module LocalAnalytics
  module ChartHelper
    CHART_COLORS = %w[#0d6efd #198754 #dc3545 #fd7e14 #6f42c1 #20c997 #ffc107 #0dcaf0 #d63384 #6c757d].freeze

    # Renders a multi-series area/line chart as inline SVG.
    #
    #   la_area_chart(
    #     series: {
    #       "Visitors" => [10, 20, 15, 30, ...],
    #       "Visits"   => [12, 25, 18, 35, ...],
    #     },
    #     labels: ["Mar 1", "Mar 2", ...],
    #     height: 220
    #   )
    # @param dashed [Array<Boolean>] per-series flag; true renders that series as a dashed line
    #   (useful for comparison/previous-period overlay)
    def la_area_chart(series:, labels: [], height: 220, width: nil, dashed: [])
      return tag.div("No data", class: "la-empty") if series.values.all?(&:empty?)

      w = width || "100%"
      view_w = 800
      view_h = height
      padding = { top: 20, right: 20, bottom: 40, left: 50 }
      chart_w = view_w - padding[:left] - padding[:right]
      chart_h = view_h - padding[:top] - padding[:bottom]

      all_values = series.values.flatten
      max_val = [all_values.max || 0, 1].max
      point_count = series.values.first&.size || 0
      return tag.div("No data", class: "la-empty") if point_count == 0

      x_step = point_count > 1 ? chart_w.to_f / (point_count - 1) : chart_w
      y_scale = chart_h.to_f / max_val

      # Y-axis grid lines (5 lines)
      grid_lines = 5
      grid_svg = (0..grid_lines).map do |i|
        y = padding[:top] + (chart_h.to_f / grid_lines * i)
        val = max_val - (max_val.to_f / grid_lines * i)
        label = val >= 1000 ? "#{(val / 1000.0).round(1)}k" : val.round(0).to_i.to_s
        %(<line x1="#{padding[:left]}" y1="#{y.round(1)}" x2="#{view_w - padding[:right]}" y2="#{y.round(1)}" stroke="#e9ecef" stroke-width="1"/>) +
        %(<text x="#{padding[:left] - 8}" y="#{(y + 4).round(1)}" text-anchor="end" fill="#6c757d" font-size="11">#{label}</text>)
      end.join

      # X-axis labels (show ~8 evenly spaced)
      label_step = [(point_count / 8.0).ceil, 1].max
      x_labels = labels.each_with_index.filter_map do |label, i|
        next unless (i % label_step).zero? || i == point_count - 1

        x = padding[:left] + i * x_step
        %(<text x="#{x.round(1)}" y="#{view_h - 5}" text-anchor="middle" fill="#6c757d" font-size="11">#{ERB::Util.html_escape(label)}</text>)
      end.join

      # Series paths + filled areas
      series_svg = series.each_with_index.map do |(name, values), si|
        color = CHART_COLORS[si % CHART_COLORS.size]
        is_dashed = dashed[si]
        points = values.each_with_index.map do |v, i|
          x = padding[:left] + i * x_step
          y = padding[:top] + chart_h - (v * y_scale)
          [x.round(2), y.round(2)]
        end

        line_d = points.map.with_index { |(x, y), i| "#{i == 0 ? 'M' : 'L'}#{x},#{y}" }.join(" ")

        # Closed area path
        area_d = line_d +
          " L#{points.last[0]},#{padding[:top] + chart_h}" \
          " L#{points.first[0]},#{padding[:top] + chart_h} Z"

        dash_attr = is_dashed ? ' stroke-dasharray="6,4"' : ""
        opacity = is_dashed ? "0.04" : "0.08"
        stroke_w = is_dashed ? "1.5" : "2"

        area = %(<path d="#{area_d}" fill="#{color}" fill-opacity="#{opacity}" stroke="none"/>)
        line = %(<path d="#{line_d}" fill="none" stroke="#{color}" stroke-width="#{stroke_w}" stroke-linejoin="round" stroke-linecap="round"#{dash_attr}/>)

        # Dots on each point (smaller for dashed/comparison series)
        dot_r = is_dashed ? "2" : "3"
        dots = points.map do |(x, y)|
          %(<circle cx="#{x}" cy="#{y}" r="#{dot_r}" fill="#{color}" stroke="#fff" stroke-width="1.5"/>)
        end.join

        area + line + dots
      end.join

      # Legend
      legend_svg = series.keys.each_with_index.map do |name, i|
        color = CHART_COLORS[i % CHART_COLORS.size]
        is_d = dashed[i]
        x = padding[:left] + i * 150
        swatch = if is_d
          %(<line x1="#{x}" y1="#{view_h - 12}" x2="#{x + 12}" y2="#{view_h - 12}" stroke="#{color}" stroke-width="2" stroke-dasharray="4,3"/>)
        else
          %(<rect x="#{x}" y="#{view_h - 18}" width="12" height="12" rx="2" fill="#{color}"/>)
        end
        swatch + %(<text x="#{x + 16}" y="#{view_h - 7}" fill="#495057" font-size="12">#{ERB::Util.html_escape(name)}</text>)
      end.join

      svg = <<~SVG
        <svg viewBox="0 0 #{view_w} #{view_h}" width="#{w}" height="#{height}" xmlns="http://www.w3.org/2000/svg" class="la-chart la-chart-area" style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
          #{grid_svg}
          #{x_labels}
          #{series_svg}
          #{legend_svg}
        </svg>
      SVG
      svg.html_safe
    end

    # Renders a horizontal bar chart as inline SVG.
    #
    #   la_bar_chart(
    #     data: [["Google", 450], ["Facebook", 230], ...],
    #     height: 200
    #   )
    def la_bar_chart(data:, height: nil, color: CHART_COLORS[0], max_bars: 10)
      data = data.first(max_bars)
      return tag.div("No data", class: "la-empty") if data.empty?

      bar_h = 28
      gap = 6
      padding = { top: 5, left: 140, right: 60 }
      view_h = height || (data.size * (bar_h + gap) + padding[:top] + 5)
      view_w = 600
      chart_w = view_w - padding[:left] - padding[:right]

      max_val = [data.map(&:last).max || 0, 1].max

      bars = data.each_with_index.map do |(label, value), i|
        y = padding[:top] + i * (bar_h + gap)
        w = (value.to_f / max_val * chart_w).round(1)
        w = [w, 2].max # minimum visible width

        label_text = ERB::Util.html_escape(label.to_s.truncate(20))
        value_text = value >= 1000 ? "#{(value / 1000.0).round(1)}k" : value.to_s

        %(<text x="#{padding[:left] - 8}" y="#{y + bar_h / 2 + 4}" text-anchor="end" fill="#495057" font-size="12">#{label_text}</text>) +
        %(<rect x="#{padding[:left]}" y="#{y}" width="#{w}" height="#{bar_h}" rx="4" fill="#{color}" fill-opacity="0.85"/>) +
        %(<text x="#{padding[:left] + w + 6}" y="#{y + bar_h / 2 + 4}" fill="#6c757d" font-size="12" font-weight="600">#{value_text}</text>)
      end.join

      svg = <<~SVG
        <svg viewBox="0 0 #{view_w} #{view_h}" width="100%" height="#{view_h}" xmlns="http://www.w3.org/2000/svg" class="la-chart la-chart-bar" style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
          #{bars}
        </svg>
      SVG
      svg.html_safe
    end

    # Renders a donut / pie chart as inline SVG.
    #
    #   la_donut_chart(
    #     data: [["Desktop", 6500], ["Mobile", 3200], ["Tablet", 300]],
    #     size: 200
    #   )
    def la_donut_chart(data:, size: 200, donut_width: 35)
      return tag.div("No data", class: "la-empty") if data.empty?

      total = data.sum(&:last).to_f
      return tag.div("No data", class: "la-empty") if total.zero?

      cx = size / 2.0
      cy = size / 2.0
      r = (size - donut_width) / 2.0 - 5
      legend_x = size + 15
      view_w = size + 200

      # Build arc segments
      current_angle = -90.0 # start at top
      segments = data.each_with_index.map do |(label, value), i|
        color = CHART_COLORS[i % CHART_COLORS.size]
        pct = value / total
        sweep = pct * 360.0
        # Skip tiny slices
        next nil if sweep < 0.5

        start_rad = current_angle * Math::PI / 180
        end_rad = (current_angle + sweep) * Math::PI / 180

        x1 = cx + r * Math.cos(start_rad)
        y1 = cy + r * Math.sin(start_rad)
        x2 = cx + r * Math.cos(end_rad)
        y2 = cy + r * Math.sin(end_rad)

        large_arc = sweep > 180 ? 1 : 0
        current_angle += sweep

        %(<path d="M#{x1.round(2)},#{y1.round(2)} A#{r},#{r} 0 #{large_arc},1 #{x2.round(2)},#{y2.round(2)}" fill="none" stroke="#{color}" stroke-width="#{donut_width}" stroke-linecap="butt"/>)
      end.compact.join

      # Center text
      center = %(<text x="#{cx}" y="#{cy - 6}" text-anchor="middle" fill="#495057" font-size="22" font-weight="700">#{total >= 1000 ? "#{(total / 1000.0).round(1)}k" : total.round(0).to_i}</text>) +
               %(<text x="#{cx}" y="#{cy + 12}" text-anchor="middle" fill="#6c757d" font-size="11">total</text>)

      # Legend
      legend = data.each_with_index.map do |(label, value), i|
        color = CHART_COLORS[i % CHART_COLORS.size]
        ly = 20 + i * 24
        pct = (value / total * 100).round(1)
        label_text = ERB::Util.html_escape(label.to_s.truncate(18))

        %(<rect x="#{legend_x}" y="#{ly}" width="14" height="14" rx="3" fill="#{color}"/>) +
        %(<text x="#{legend_x + 20}" y="#{ly + 12}" fill="#495057" font-size="12">#{label_text}</text>) +
        %(<text x="#{legend_x + 160}" y="#{ly + 12}" fill="#6c757d" font-size="12" text-anchor="end">#{pct}%</text>)
      end.join

      svg = <<~SVG
        <svg viewBox="0 0 #{view_w} #{[size, data.size * 24 + 30].max}" width="100%" height="#{[size, data.size * 24 + 30].max}" xmlns="http://www.w3.org/2000/svg" class="la-chart la-chart-donut" style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
          #{segments}
          #{center}
          #{legend}
        </svg>
      SVG
      svg.html_safe
    end

    # Simple sparkline for metric cards — tiny inline area chart.
    #
    #   la_sparkline(values: [10, 20, 15, 30], color: "#0d6efd")
    def la_sparkline(values:, color: CHART_COLORS[0], width: 120, height: 32)
      return "" if values.nil? || values.size < 2

      max_val = [values.max, 1].max
      x_step = width.to_f / (values.size - 1)
      y_scale = (height - 4).to_f / max_val

      points = values.each_with_index.map do |v, i|
        x = (i * x_step).round(2)
        y = (height - 2 - v * y_scale).round(2)
        [x, y]
      end

      line_d = points.map.with_index { |(x, y), i| "#{i == 0 ? 'M' : 'L'}#{x},#{y}" }.join(" ")
      area_d = line_d + " L#{points.last[0]},#{height} L#{points.first[0]},#{height} Z"

      svg = <<~SVG
        <svg viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg" class="la-sparkline">
          <path d="#{area_d}" fill="#{color}" fill-opacity="0.12"/>
          <path d="#{line_d}" fill="none" stroke="#{color}" stroke-width="1.5" stroke-linejoin="round"/>
        </svg>
      SVG
      svg.html_safe
    end
  end
end
