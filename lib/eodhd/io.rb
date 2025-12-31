# frozen_string_literal: true

require "fileutils"
require "json"

module Eodhd
  class Io
    def initialize(output_dir:)
      @output_dir = Validate.required_string!("output_dir", output_dir)
    end

    def save_mcd_csv!(csv:)
      save_csv!(relative_path: "data/MCD.US.csv", csv: csv)
    end

    def save_exchanges_list_json!(json:)
      save_json!(relative_path: "exchanges-list.json", json: json, pretty: true)
    end

    private

    def save_csv!(relative_path:, csv:)
      csv = Validate.required_string!("csv", csv)
      relative_path = Validate.required_string!("relative_path", relative_path)

      write_text_file!(
        relative_path: relative_path,
        content: csv,
        ensure_trailing_newline: false
      )
    end

    def save_json!(relative_path:, json:, pretty: true)
      json = Validate.required_string!("json", json)
      relative_path = Validate.required_string!("relative_path", relative_path)

      content = pretty ? pretty_json(json) : json

      write_text_file!(
        relative_path: relative_path,
        content: content,
        ensure_trailing_newline: true
      )
    end

    def pretty_json(json)
      JSON.pretty_generate(JSON.parse(json))
    rescue JSON::ParserError
      json
    end

    def write_text_file!(relative_path:, content:, ensure_trailing_newline:)
      output_path = File.join(@output_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(output_path))

      content = content.to_s
      content += "\n" if ensure_trailing_newline && !content.end_with?("\n")

      File.write(output_path, content)
      output_path
    end
  end
end
