# frozen_string_literal: true

require "zeitwerk"

module Util
end

loader = Zeitwerk::Loader.new
loader.push_dir(File.join(__dir__, "util"), namespace: Util)
loader.setup
