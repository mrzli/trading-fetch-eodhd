# frozen_string_literal: true

require "fileutils"
require "json"

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

    def save_exchanges_list_json!(json:, output_dir:)
      json = Validate.required_string!("json", json)
      output_dir = Validate.required_string!("output_dir", output_dir)

      FileUtils.mkdir_p(output_dir)
      output_path = File.join(output_dir, "exchanges-list.json")

      pretty = begin
        JSON.pretty_generate(JSON.parse(json))
      rescue JSON::ParserError
        json
      end

      File.write(output_path, pretty.end_with?("\n") ? pretty : (pretty + "\n"))
      output_path
    end
  end
end
