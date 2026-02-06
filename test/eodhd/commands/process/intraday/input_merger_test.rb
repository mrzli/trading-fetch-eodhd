# frozen_string_literal: true

require_relative "../../../../test_helper"
require_relative "../../../../../lib/eodhd/commands/process/intraday/input_merger"

describe Eodhd::Commands::InputMerger do
  it "concats when disjoint" do
    a = [
      { timestamp: 100, v: :a1 },
      { timestamp: 200, v: :a2 }
    ]
    b = [
      { timestamp: 300, v: :b1 }
    ]

    merged = Eodhd::Commands::InputMerger.merge([a, b])

    _(merged).must_equal [
      { timestamp: 100, v: :a1 },
      { timestamp: 200, v: :a2 },
      { timestamp: 300, v: :b1 }
    ]
  end

  it "drops overlapping tail from first and keeps later data" do
    a = [
      { timestamp: 100, v: :a1 },
      { timestamp: 200, v: :old },
      { timestamp: 250, v: :old2 }
    ]
    b = [
      { timestamp: 200, v: :b1 },
      { timestamp: 300, v: :b2 }
    ]

    merged = Eodhd::Commands::InputMerger.merge([a, b])

    _(merged).must_equal [
      { timestamp: 100, v: :a1 },
      { timestamp: 200, v: :b1 },
      { timestamp: 300, v: :b2 }
    ]
  end

  it "handles nil and empty inputs" do
    merged = Eodhd::Commands::InputMerger.merge([nil, [], [{ timestamp: 1, v: :x }]])
    _(merged).must_equal [{ timestamp: 1, v: :x }]
  end
end
