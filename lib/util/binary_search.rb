# frozen_string_literal: true

module BinarySearch
  class << self
    # Finds the smallest index i where array[i] >= value (using the provided comparison)
    # If block given, uses block to extract comparable value: block.call(array[i]) >= value
    # Returns array.length if all elements are < value
    def lower_bound(array, value, &block)
      return 0 if array.nil? || array.empty?

      lo = 0
      hi = array.length

      while lo < hi
        mid = (lo + hi) / 2
        mid_value = block ? block.call(array[mid]) : array[mid]

        if mid_value < value
          lo = mid + 1
        else
          hi = mid
        end
      end

      lo
    end

    # Finds the smallest index i where array[i] > value (using the provided comparison)
    # If block given, uses block to extract comparable value: block.call(array[i]) > value
    # Returns array.length if all elements are <= value
    def upper_bound(array, value, &block)
      return 0 if array.nil? || array.empty?

      lo = 0
      hi = array.length

      while lo < hi
        mid = (lo + hi) / 2
        mid_value = block ? block.call(array[mid]) : array[mid]

        if mid_value <= value
          lo = mid + 1
        else
          hi = mid
        end
      end

      lo
    end

    # Finds the exact match index where array[i] == value
    # If block given, uses block to extract comparable value: block.call(array[i]) == value
    # Returns nil if not found
    def exact(array, value, &block)
      idx = lower_bound(array, value, &block)
      return nil if idx >= array.length

      found_value = block ? block.call(array[idx]) : array[idx]
      found_value == value ? idx : nil
    end

    # Finds the greatest index i where array[i] < value
    # If block given, uses block to extract comparable value: block.call(array[i]) < value
    # Returns nil if all elements are >= value
    def greatest_lt(array, value, &block)
      idx = lower_bound(array, value, &block)
      idx > 0 ? idx - 1 : nil
    end

    # Finds the greatest index i where array[i] <= value
    # If block given, uses block to extract comparable value: block.call(array[i]) <= value
    # Returns nil if all elements are > value
    def greatest_lte(array, value, &block)
      idx = upper_bound(array, value, &block)
      idx > 0 ? idx - 1 : nil
    end

    # Finds the smallest index i where array[i] >= value
    # Alias for lower_bound for clarity
    def smallest_gte(array, value, &block)
      idx = lower_bound(array, value, &block)
      idx < array.length ? idx : nil
    end

    # Finds the smallest index i where array[i] > value
    # Alias for upper_bound for clarity
    def smallest_gt(array, value, &block)
      idx = upper_bound(array, value, &block)
      idx < array.length ? idx : nil
    end
  end
end
