# frozen_string_literal: true

require "fileutils"

module Eodhd
  module Fetch
    module_function

    def fetch_mcd_csv!(api_token:, base_url:)
      api = Api.new(base_url: base_url, api_token: api_token)
      api.fetch_mcd_csv!
    end

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
