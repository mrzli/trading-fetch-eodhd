# frozen_string_literal: true

require "zeitwerk"
require_relative "util"
require_relative "logging"

module Eodhd
end

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "eodhd"), namespace: Eodhd)
loader.setup
