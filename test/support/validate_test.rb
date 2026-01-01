# frozen_string_literal: true

require_relative "../test_helper"

describe Eodhd::Validate do
  describe ".required_string!" do
    it "strips whitespace" do
      assert_equal "abc", Eodhd::Validate.required_string!("x", "  abc  ")
    end

    it "raises on nil" do
      assert_raises(ArgumentError) do
        Eodhd::Validate.required_string!("x", nil)
      end
    end

    it "raises on blank" do
      assert_raises(ArgumentError) do
        Eodhd::Validate.required_string!("x", "  d ")
      end
    end
  end

  describe ".http_url!" do
    it "accepts http(s) and strips trailing slash" do
      assert_equal "https://example.com", Eodhd::Validate.http_url!("base", "https://example.com/")
      assert_equal "http://example.com/api", Eodhd::Validate.http_url!("base", "http://example.com/api")
    end

    it "rejects non-http urls" do
      err = assert_raises(ArgumentError) do
        Eodhd::Validate.http_url!("base", "ftp://example.com")
      end
      assert_match(/must start with http:\/\/ or https:\/\//, err.message)
    end

    it "rejects blank" do
      assert_raises(ArgumentError) do
        Eodhd::Validate.http_url!("base", "")
      end
    end
  end
end
