# frozen_string_literal: true

require "fileutils"
require "json"

module Eodhd
  class Io
    def initialize(output_dir:)
      @output_dir = Validate.required_string!("output_dir", output_dir)
    end

    def save_mcd_csv!(csv:)
      csv = Validate.required_string!("csv", csv)

      write_text_file!(
        filename: "MCD.US.csv",
        content: csv,
        ensure_trailing_newline: false
      )
    end

    def save_exchanges_list_json!(json:)
      json = Validate.required_string!("json", json)

      pretty = begin
        JSON.pretty_generate(JSON.parse(json))
      rescue JSON::ParserError
        json
      end

      write_text_file!(
        filename: "exchanges-list.json",
        content: pretty,
        ensure_trailing_newline: true
      )
    end

    private

    def write_text_file!(filename:, content:, ensure_trailing_newline:)
      FileUtils.mkdir_p(@output_dir)
      output_path = File.join(@output_dir, filename)

      content = content.to_s
      content += "\n" if ensure_trailing_newline && !content.end_with?("\n")

      File.write(output_path, content)
      output_path
    end
  end
end
