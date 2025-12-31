# frozen_string_literal: true

require "fileutils"

module Eodhd
  module Io
    module_function

    def save_mcd_csv!(csv:, output_dir:)
      csv = Validate.required_string!("csv", csv)
      output_dir = Validate.required_string!("output_dir", output_dir)

      FileUtils.mkdir_p(output_dir)
      output_path = File.join(output_dir, "MCD.US.csv")
      File.write(output_path, csv)
      output_path
    end
  end
end
