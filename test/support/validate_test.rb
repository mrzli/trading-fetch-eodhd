# frozen_string_literal: true

require_relative "../test_helper"

class ValidateTest < Minitest::Test
  def test_required_string_strips
    assert_equal "abc", Eodhd::Validate.required_string!("x", "  abc  ")
  end

  def test_required_string_raises_on_nil
    assert_raises(ArgumentError) do
      Eodhd::Validate.required_string!("x", nil)
    end
  end

  def test_required_string_raises_on_blank
    assert_raises(ArgumentError) do
      Eodhd::Validate.required_string!("x", "   ")
    end
  end

  def test_http_url_accepts_http_and_strips_trailing_slash
    assert_equal "https://example.com", Eodhd::Validate.http_url!("base", "https://example.com/")
    assert_equal "http://example.com/api", Eodhd::Validate.http_url!("base", "http://example.com/api")
  end

  def test_http_url_rejects_non_http
    err = assert_raises(ArgumentError) do
      Eodhd::Validate.http_url!("base", "ftp://example.com")
    end
    assert_match(/must start with http:\/\/ or https:\/\//, err.message)
  end

  def test_http_url_rejects_blank
    assert_raises(ArgumentError) do
      Eodhd::Validate.http_url!("base", "")
    end
  end
end
