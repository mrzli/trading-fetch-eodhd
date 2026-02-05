# frozen_string_literal: true

require_relative "../../../../test_helper"
require_relative "../../../../../lib/eodhd/fetch/components/intraday/intraday_csv_merger"

describe Eodhd::IntradayCsvMerger do
  def row(timestamp)
    { timestamp: timestamp, gmtoffset: 0, datetime: "2025-01-01 00:00:00", open: 100, high: 101, low: 99, close: 100, volume: 1000 }
  end

  describe ".merge" do
    it "returns new rows when existing is nil" do
      new_rows = [row(100), row(200)]
      result = Eodhd::IntradayCsvMerger.merge(nil, new_rows)
      _(result).must_equal new_rows
    end

    it "returns new rows when existing is empty" do
      new_rows = [row(100), row(200)]
      result = Eodhd::IntradayCsvMerger.merge([], new_rows)
      _(result).must_equal new_rows
    end

    it "returns existing rows when new is nil" do
      existing_rows = [row(100), row(200)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, nil)
      _(result).must_equal existing_rows
    end

    it "returns existing rows when new is empty" do
      existing_rows = [row(100), row(200)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, [])
      _(result).must_equal existing_rows
    end

    it "handles no overlap - new data after existing" do
      existing_rows = [row(100), row(200), row(300)]
      new_rows = [row(500), row(600)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(300), row(500), row(600)]
    end

    it "handles no overlap - new data before existing" do
      existing_rows = [row(500), row(600), row(700)]
      new_rows = [row(100), row(200)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(500), row(600), row(700)]
    end

    it "handles adjacent ranges - new data immediately after existing" do
      existing_rows = [row(100), row(200), row(300)]
      new_rows = [row(301), row(400)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(300), row(301), row(400)]
    end

    it "handles adjacent ranges - new data immediately before existing" do
      existing_rows = [row(300), row(400), row(500)]
      new_rows = [row(100), row(299)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(299), row(300), row(400), row(500)]
    end

    it "handles partial overlap - new data overlaps end of existing" do
      existing_rows = [row(100), row(200), row(300), row(400)]
      new_rows = [row(250), row(350), row(450)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(250), row(350), row(450)]
    end

    it "handles partial overlap - new data overlaps start of existing" do
      existing_rows = [row(300), row(400), row(500), row(600)]
      new_rows = [row(200), row(350), row(450)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(200), row(350), row(450), row(500), row(600)]
    end

    it "handles new data completely within existing (subset)" do
      existing_rows = [row(100), row(200), row(300), row(400), row(500)]
      new_rows = [row(250), row(350)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(250), row(350), row(400), row(500)]
    end

    it "handles new data completely containing existing (superset)" do
      existing_rows = [row(300), row(400)]
      new_rows = [row(100), row(200), row(300), row(400), row(500), row(600)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(300), row(400), row(500), row(600)]
    end

    it "handles complete replacement - exact same range" do
      existing_rows = [row(100), row(200), row(300)]
      new_rows = [row(100), row(200), row(300)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(300)]
    end

    it "handles boundary inclusion - excludes start timestamp" do
      existing_rows = [row(100), row(200), row(300), row(400)]
      new_rows = [row(200), row(250)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(250), row(300), row(400)]
    end

    it "handles boundary inclusion - excludes end timestamp" do
      existing_rows = [row(100), row(200), row(300), row(400)]
      new_rows = [row(250), row(300)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(250), row(300), row(400)]
    end

    it "handles replacing middle section with gap before and after" do
      existing_rows = [row(100), row(200), row(500), row(600), row(900), row(1000)]
      new_rows = [row(550), row(650), row(750)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(500), row(550), row(650), row(750), row(900), row(1000)]
    end

    it "handles exclude range covering all existing data" do
      existing_rows = [row(200), row(300), row(400)]
      new_rows = [row(100), row(500)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(500)]
    end

    it "handles exclude range with no matching existing data" do
      existing_rows = [row(100), row(200), row(700), row(800)]
      new_rows = [row(400), row(500)]
      result = Eodhd::IntradayCsvMerger.merge(existing_rows, new_rows)
      _(result).must_equal [row(100), row(200), row(400), row(500), row(700), row(800)]
    end
  end
end
