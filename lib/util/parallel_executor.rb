# frozen_string_literal: true

require "parallel"

module Util
  class ParallelExecutor
    def self.execute(items, parallel:, workers:, &block)
      if parallel
        Parallel.each(items, in_processes: workers, &block)
      else
        items.each(&block)
      end
    end

    def self.map(items, parallel:, workers:, &block)
      if parallel
        Parallel.map(items, in_processes: workers, &block)
      else
        items.map(&block)
      end
    end
  end
end
