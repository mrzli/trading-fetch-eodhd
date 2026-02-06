# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "minitest/spec"
require "eodhd"
require "util"

require_relative "test_util/data_driven"
include TestSupport::DataDriven
