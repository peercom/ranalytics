# frozen_string_literal: true

require "spec_helper"

RSpec.describe LocalAnalytics::ChartHelper, type: :helper do
  describe "#la_area_chart" do
    it "renders an SVG element" do
      html = helper.la_area_chart(
        series: { "Visits" => [10, 20, 15, 30, 25] },
        labels: %w[Mon Tue Wed Thu Fri]
      )
      expect(html).to include("<svg")
      expect(html).to include("la-chart-area")
      expect(html).to include("Visits")
    end

    it "handles multi-series" do
      html = helper.la_area_chart(
        series: {
          "Visitors" => [5, 10, 8],
          "Pageviews" => [12, 25, 18]
        },
        labels: %w[A B C]
      )
      expect(html).to include("Visitors")
      expect(html).to include("Pageviews")
    end

    it "handles empty data" do
      html = helper.la_area_chart(series: { "X" => [] }, labels: [])
      expect(html).to include("No data")
    end

    it "handles all-zero data" do
      html = helper.la_area_chart(
        series: { "Visits" => [0, 0, 0] },
        labels: %w[A B C]
      )
      expect(html).to include("<svg")
    end
  end

  describe "#la_bar_chart" do
    it "renders an SVG with bars" do
      html = helper.la_bar_chart(data: [["Google", 450], ["Facebook", 230]])
      expect(html).to include("<svg")
      expect(html).to include("la-chart-bar")
      expect(html).to include("Google")
      expect(html).to include("Facebook")
    end

    it "handles empty data" do
      html = helper.la_bar_chart(data: [])
      expect(html).to include("No data")
    end

    it "limits to max_bars" do
      data = (1..20).map { |i| ["Item #{i}", i * 10] }
      html = helper.la_bar_chart(data: data, max_bars: 5)
      expect(html).to include("Item 1")
      expect(html).not_to include("Item 6")
    end
  end

  describe "#la_donut_chart" do
    it "renders an SVG donut" do
      html = helper.la_donut_chart(
        data: [["Desktop", 6500], ["Mobile", 3200], ["Tablet", 300]]
      )
      expect(html).to include("<svg")
      expect(html).to include("la-chart-donut")
      expect(html).to include("Desktop")
      expect(html).to include("Mobile")
      expect(html).to include("Tablet")
      # Should show percentages
      expect(html).to match(/\d+\.\d+%/)
    end

    it "handles single item" do
      html = helper.la_donut_chart(data: [["All", 100]])
      expect(html).to include("<svg")
      expect(html).to include("100.0%")
    end

    it "handles empty data" do
      html = helper.la_donut_chart(data: [])
      expect(html).to include("No data")
    end
  end

  describe "#la_sparkline" do
    it "renders a small SVG" do
      html = helper.la_sparkline(values: [10, 20, 15, 30])
      expect(html).to include("<svg")
      expect(html).to include("la-sparkline")
    end

    it "returns empty for insufficient data" do
      expect(helper.la_sparkline(values: [10])).to eq("")
      expect(helper.la_sparkline(values: nil)).to eq("")
    end
  end
end
