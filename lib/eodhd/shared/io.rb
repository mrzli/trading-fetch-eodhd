# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"

module Eodhd
  class Io
    def initialize(output_dir:)
      @output_dir = Validate.required_string!("output_dir", output_dir)
    end

    def output_path(relative_path)
      relative_path = Validate.required_string!("relative_path", relative_path)
      File.join(@output_dir, relative_path)
    end

    def relative_path(output_path)
      output_path = Validate.required_string!("output_path", output_path)
      Pathname.new(output_path).relative_path_from(Pathname.new(@output_dir)).to_s
    end

    def file_exists?(relative_path)
      File.exist?(output_path(relative_path))
    end

    def file_last_updated_at(relative_path)
      output_path = output_path(relative_path)
      return nil unless File.exist?(output_path)

      File.mtime(output_path)
    end

    def read_text(relative_path)
      File.read(output_path(relative_path))
    end

    def list_relative_paths(relative_dir)
      relative_dir = Validate.required_string!("relative_dir", relative_dir)
      dir_path = output_path(relative_dir)
      return [] unless Dir.exist?(dir_path)

      Dir.children(dir_path).filter_map do |name|
        relative_path = File.join(relative_dir, name)
        absolute_path = output_path(relative_path)
        next unless File.file?(absolute_path)

        relative_path
      end
    end

    def save_csv!(relative_path, csv)
      csv = Validate.required_string!("csv", csv)

      write_text_file!(relative_path, csv, false)
    end

    def save_json!(relative_path, json, pretty = true)
      json = Validate.required_string!("json", json)

      content = pretty ? pretty_json(json) : json

      write_text_file!(relative_path, content, true)
    end

    def delete_dir!(relative_dir)
      relative_dir = Validate.required_string!("relative_dir", relative_dir)
      if relative_dir.include?("..") || relative_dir.start_with?("/")
        raise ArgumentError, "relative_dir must be a safe relative path."
      end

      full_path = output_path(relative_dir)

      FileUtils.rm_rf(full_path)
    end

    private

    def pretty_json(json)
      JSON.pretty_generate(JSON.parse(json))
    rescue JSON::ParserError
      json
    end

    def write_text_file!(relative_path, content, ensure_trailing_newline)
      output_path = output_path(relative_path)
      FileUtils.mkdir_p(File.dirname(output_path))

      content = content.to_s
      content += "\n" if ensure_trailing_newline && !content.end_with?("\n")

      File.write(output_path, content)
      output_path
    end
  end
end
