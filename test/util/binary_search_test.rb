# frozen_string_literal: true

require_relative "../test_helper"

describe Util::BinarySearch do
  describe ".lower_bound" do
    it "returns 0 for empty array" do
      result = Util::BinarySearch.lower_bound([], 5)
      assert_equal 0, result
    end

    it "returns 0 for nil array" do
      result = Util::BinarySearch.lower_bound(nil, 5)
      assert_equal 0, result
    end

    it "finds smallest index where element >= value" do
      arr = [1, 3, 3, 5, 7, 9]
      
      assert_equal 0, Util::BinarySearch.lower_bound(arr, 0)
      assert_equal 0, Util::BinarySearch.lower_bound(arr, 1)
      assert_equal 1, Util::BinarySearch.lower_bound(arr, 2)
      assert_equal 1, Util::BinarySearch.lower_bound(arr, 3)
      assert_equal 3, Util::BinarySearch.lower_bound(arr, 4)
      assert_equal 3, Util::BinarySearch.lower_bound(arr, 5)
      assert_equal 6, Util::BinarySearch.lower_bound(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.lower_bound(arr, 250) { |item| item[:timestamp] }
      assert_equal 2, result
    end
  end

  describe ".upper_bound" do
    it "returns 0 for empty array" do
      result = Util::BinarySearch.upper_bound([], 5)
      assert_equal 0, result
    end

    it "finds smallest index where element > value" do
      arr = [1, 3, 3, 5, 7, 9]
      
      assert_equal 0, Util::BinarySearch.upper_bound(arr, 0)
      assert_equal 1, Util::BinarySearch.upper_bound(arr, 1)
      assert_equal 1, Util::BinarySearch.upper_bound(arr, 2)
      assert_equal 3, Util::BinarySearch.upper_bound(arr, 3)
      assert_equal 3, Util::BinarySearch.upper_bound(arr, 4)
      assert_equal 4, Util::BinarySearch.upper_bound(arr, 5)
      assert_equal 6, Util::BinarySearch.upper_bound(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.upper_bound(arr, 200) { |item| item[:timestamp] }
      assert_equal 2, result
    end
  end

  describe ".exact" do
    it "returns nil for empty array" do
      result = Util::BinarySearch.exact([], 5)
      assert_nil result
    end

    it "finds exact match" do
      arr = [1, 3, 5, 7, 9]
      
      assert_equal 0, Util::BinarySearch.exact(arr, 1)
      assert_equal 2, Util::BinarySearch.exact(arr, 5)
      assert_equal 4, Util::BinarySearch.exact(arr, 9)
    end

    it "returns nil when not found" do
      arr = [1, 3, 5, 7, 9]
      
      assert_nil Util::BinarySearch.exact(arr, 0)
      assert_nil Util::BinarySearch.exact(arr, 2)
      assert_nil Util::BinarySearch.exact(arr, 4)
      assert_nil Util::BinarySearch.exact(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 }
      ]

      result = Util::BinarySearch.exact(arr, 200) { |item| item[:timestamp] }
      assert_equal 1, result

      result = Util::BinarySearch.exact(arr, 250) { |item| item[:timestamp] }
      assert_nil result
    end
  end

  describe ".last_lt" do
    it "returns nil for empty array" do
      result = Util::BinarySearch.last_lt([], 5)
      assert_nil result
    end

    it "finds greatest index where element < value" do
      arr = [1, 3, 5, 7, 9]
      
      assert_nil Util::BinarySearch.last_lt(arr, 0)
      assert_nil Util::BinarySearch.last_lt(arr, 1)
      assert_equal 0, Util::BinarySearch.last_lt(arr, 2)
      assert_equal 1, Util::BinarySearch.last_lt(arr, 4)
      assert_equal 2, Util::BinarySearch.last_lt(arr, 6)
      assert_equal 4, Util::BinarySearch.last_lt(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.last_lt(arr, 250) { |item| item[:timestamp] }
      assert_equal 1, result
    end
  end

  describe ".last_lte" do
    it "returns nil for empty array" do
      result = Util::BinarySearch.last_lte([], 5)
      assert_nil result
    end

    it "finds greatest index where element <= value" do
      arr = [1, 3, 5, 7, 9]
      
      assert_nil Util::BinarySearch.last_lte(arr, 0)
      assert_equal 0, Util::BinarySearch.last_lte(arr, 1)
      assert_equal 0, Util::BinarySearch.last_lte(arr, 2)
      assert_equal 1, Util::BinarySearch.last_lte(arr, 3)
      assert_equal 2, Util::BinarySearch.last_lte(arr, 5)
      assert_equal 2, Util::BinarySearch.last_lte(arr, 6)
      assert_equal 4, Util::BinarySearch.last_lte(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.last_lte(arr, 200) { |item| item[:timestamp] }
      assert_equal 1, result

      result = Util::BinarySearch.last_lte(arr, 250) { |item| item[:timestamp] }
      assert_equal 1, result
    end
  end

  describe ".first_gte" do
    it "returns nil for empty array" do
      result = Util::BinarySearch.first_gte([], 5)
      assert_nil result
    end

    it "finds smallest index where element >= value" do
      arr = [1, 3, 5, 7, 9]
      
      assert_equal 0, Util::BinarySearch.first_gte(arr, 0)
      assert_equal 0, Util::BinarySearch.first_gte(arr, 1)
      assert_equal 1, Util::BinarySearch.first_gte(arr, 2)
      assert_equal 2, Util::BinarySearch.first_gte(arr, 5)
      assert_equal 4, Util::BinarySearch.first_gte(arr, 8)
      assert_nil Util::BinarySearch.first_gte(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.first_gte(arr, 250) { |item| item[:timestamp] }
      assert_equal 2, result
    end
  end

  describe ".first_gt" do
    it "returns nil for empty array" do
      result = Util::BinarySearch.first_gt([], 5)
      assert_nil result
    end

    it "finds smallest index where element > value" do
      arr = [1, 3, 5, 7, 9]
      
      assert_equal 0, Util::BinarySearch.first_gt(arr, 0)
      assert_equal 1, Util::BinarySearch.first_gt(arr, 1)
      assert_equal 1, Util::BinarySearch.first_gt(arr, 2)
      assert_equal 2, Util::BinarySearch.first_gt(arr, 3)
      assert_equal 3, Util::BinarySearch.first_gt(arr, 5)
      assert_nil Util::BinarySearch.first_gt(arr, 10)
    end

    it "works with block to extract value" do
      arr = [
        { timestamp: 100 },
        { timestamp: 200 },
        { timestamp: 300 },
        { timestamp: 500 }
      ]

      result = Util::BinarySearch.first_gt(arr, 200) { |item| item[:timestamp] }
      assert_equal 2, result
    end
  end
end
