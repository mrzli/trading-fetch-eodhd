# frozen_string_literal: true

require_relative "../../../../test_helper"
require_relative "../../../../../lib/eodhd/fetch/components/intraday/intraday_csv_merger"

describe Eodhd::IntradayCsvMerger do
  def rowe(timestamp)
    { timestamp: timestamp, gmtoffset: 0, datetime: "2025-01-01 00:00:00", open: 100, high: 101, low: 99, close: 100, volume: 1000 }
  end

  def rown(timestamp)
    { timestamp: timestamp, gmtoffset: 0, datetime: "2025-01-01 00:00:00", open: 200, high: 201, low: 199, close: 200, volume: 2000 }
  end

  def rowse(*timestamps)
    timestamps.map { |ts| rowe(ts) }
  end

  def rowsn(*timestamps)
    timestamps.map { |ts| rown(ts) }
  end

  describe ".merge" do
    it "returns new rows when existing is nil" do
      existing_csv = nil
      new_csv = rowsn(100, 200)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      _(result).must_equal new_csv
    end

    it "returns new rows when existing is empty" do
      existing_csv = []
      new_csv = rowsn(100, 200)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      _(result).must_equal new_csv
    end

    it "returns existing rows when new is nil" do
      existing_csv = rowse(100, 200)
      new_csv = nil
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      _(result).must_equal existing_csv
    end

    it "returns existing rows when new is empty" do
      existing_csv = rowse(100, 200)
      new_csv = []
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      _(result).must_equal existing_csv
    end

    it "handles no overlap - new data after existing" do
      existing_csv = rowse(100, 200, 300)
      new_csv = rowsn(500, 600)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200, 300) + rowsn(500, 600)
      _(result).must_equal expected
    end

    it "handles no overlap - new data before existing" do
      existing_csv = rowse(500, 600, 700)
      new_csv = rowsn(100, 200)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowsn(100, 200) + rowse(500, 600, 700)
      _(result).must_equal expected
    end

    it "handles new data starting at existing timestamp" do
      existing_csv = rowse(100, 200, 300, 400)
      new_csv = rowsn(200, 250)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100) + rowsn(200, 250) + rowse(300, 400)
      _(result).must_equal expected
    end

    it "handles new data ending at existing timestamp" do
      existing_csv = rowse(100, 200, 300, 400)
      new_csv = rowsn(250, 300)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200) + rowsn(250, 300) + rowse(400)
      _(result).must_equal expected
    end

    it "handles partial overlap - new data overlaps end of existing" do
      existing_csv = rowse(100, 200, 300, 400)
      new_csv = rowsn(250, 350, 450)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200) + rowsn(250, 350, 450)
      _(result).must_equal expected
    end

    it "handles partial overlap - new data overlaps start of existing" do
      existing_csv = rowse(300, 400, 500, 600)
      new_csv = rowsn(200, 350, 450)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowsn(200, 350, 450) + rowse(500, 600)
      _(result).must_equal expected
    end

    it "handles new data completely within existing (subset)" do
      existing_csv = rowse(100, 200, 300, 400, 500)
      new_csv = rowsn(250, 350)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200) + rowsn(250, 350) + rowse(400, 500)
      _(result).must_equal expected
    end

    it "handles new data completely containing existing (superset)" do
      existing_csv = rowse(300, 400)
      new_csv = rowsn(100, 200, 300, 400, 500, 600)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowsn(100, 200, 300, 400, 500, 600)
      _(result).must_equal expected
    end

    it "handles complete replacement - exact same range" do
      existing_csv = rowse(100, 200, 300)
      new_csv = rowsn(100, 200, 300)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowsn(100, 200, 300)
      _(result).must_equal expected
    end

    it "handles replacing middle section with gap before and after" do
      existing_csv = rowse(100, 200, 500, 600, 900, 1000)
      new_csv = rowsn(550, 650, 750)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200, 500) + rowsn(550, 650, 750) + rowse(900, 1000)
      _(result).must_equal expected
    end

    it "handles exclude range covering all existing data" do
      existing_csv = rowse(200, 300, 400)
      new_csv = rowsn(100, 500)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowsn(100, 500)
      _(result).must_equal expected
    end

    it "handles exclude range with no matching existing data" do
      existing_csv = rowse(100, 200, 700, 800)
      new_csv = rowsn(400, 500)
      result = Eodhd::IntradayCsvMerger.merge(existing_csv, new_csv)
      expected = rowse(100, 200) + rowsn(400, 500) + rowse(700, 800)
      _(result).must_equal expected
    end
  end
end
