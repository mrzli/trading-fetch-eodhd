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

    def file_exists?(relative_path:)
      File.exist?(output_path(relative_path: relative_path))
    end

    def file_last_updated_at(relative_path:)
      output_path = output_path(relative_path: relative_path)
      return nil unless File.exist?(output_path)

      File.mtime(output_path)
    end

    def save_csv!(relative_path:, csv:)
      csv = Validate.required_string!("csv", csv)

      write_text_file!(
        relative_path: relative_path,
        content: csv,
        ensure_trailing_newline: false
      )
    end

    def save_json!(relative_path:, json:, pretty: true)
      json = Validate.required_string!("json", json)

      content = pretty ? pretty_json(json) : json

      write_text_file!(
        relative_path: relative_path,
        content: content,
        ensure_trailing_newline: true
      )
    end

    private

    def output_path(relative_path:)
      relative_path = Validate.required_string!("relative_path", relative_path)
      File.join(@output_dir, relative_path)
    end

    def pretty_json(json)
      JSON.pretty_generate(JSON.parse(json))
    rescue JSON::ParserError
      json
    end

    def write_text_file!(relative_path:, content:, ensure_trailing_newline:)
      output_path = output_path(relative_path: relative_path)
      FileUtils.mkdir_p(File.dirname(output_path))

      content = content.to_s
      content += "\n" if ensure_trailing_newline && !content.end_with?("\n")

      File.write(output_path, content)
      output_path
    end
  end
end
