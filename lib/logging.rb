# frozen_string_literal: true

require "zeitwerk"

module Logging
end

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "logging"), namespace: Logging)
loader.setup
