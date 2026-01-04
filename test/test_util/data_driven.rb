# frozen_string_literal: true

require "json"

module TestSupport
  module DataDriven
    module_function

    def test_equals(title, items, call:)
      describe(title) do
        items.each do |item|
          input = fetch(item, :input)
          expected = fetch(item, :expected)
          label = fetch_optional(item, :description) || stringify_input(input)

          it(label) do
            assert_equal expected, call.call(input)
          end
        end
      end
    end

    def test_raises(title, items, call:)
      describe(title) do
        items.each do |item|
          input = fetch(item, :input)
          exception = fetch_optional(item, :exception)
          label = fetch_optional(item, :description) || stringify_input(input)

          it(label) do
            if exception
              assert_raises(exception) { call.call(input) }
            else
              raised = false
              begin
                call.call(input)
              rescue Exception
                raised = true
              end
              assert raised, "Expected an exception to be raised"
            end
          end
        end
      end
    end

    private_class_method

    def stringify_input(input)
      JSON.generate(input)
    rescue JSON::GeneratorError, TypeError
      input.inspect
    end

    def fetch(hash, key)
      return hash[key] if hash.is_a?(Hash) && hash.key?(key)
      return hash[key.to_s] if hash.is_a?(Hash) && hash.key?(key.to_s)

      raise KeyError, "Missing #{key}"
    end

    def fetch_optional(hash, key)
      return nil unless hash.is_a?(Hash)
      return hash[key] if hash.key?(key)
      return hash[key.to_s] if hash.key?(key.to_s)

      nil
    end
  end
end
