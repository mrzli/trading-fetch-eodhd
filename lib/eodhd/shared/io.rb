# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"

module Eodhd
  module Shared
    class Io
      def initialize(output_dir:)
        @output_dir = Util::Validate.required_string("output_dir", output_dir)
      end

      # Path - start
      def output_path(relative_path)
        relative_path = Util::Validate.required_string("relative_path", relative_path)
        File.join(@output_dir, relative_path)
      end

      def relative_path(output_path)
        output_path = Util::Validate.required_string("output_path", output_path)
        Pathname.new(output_path).relative_path_from(Pathname.new(@output_dir)).to_s
      end

      def list_relative_entries(relative_dir)
        relative_dir = Util::Validate.required_string("relative_dir", relative_dir)
        dir_path = output_path(relative_dir)
        return [] unless Dir.exist?(dir_path)
        Dir.children(dir_path)
      end

      def list_relative_files(relative_dir)
        list_relative_entries(relative_dir).filter_map do |name|
          absolute_path = output_path(File.join(relative_dir, name))
          next unless File.file?(absolute_path)
          File.join(relative_dir, name)
        end
      end

      def list_relative_dirs(relative_dir)
        list_relative_entries(relative_dir).filter_map do |name|
          absolute_path = output_path(File.join(relative_dir, name))
          next unless File.directory?(absolute_path)
          File.join(relative_dir, name)
        end
      end
      # Path - end

      # File info - start
      def file_exists?(relative_path)
        File.exist?(output_path(relative_path))
      end

      def dir_exists?(relative_dir)
        File.directory?(output_path(relative_dir))
      end

      def file_last_updated_at(relative_path)
        output_path = output_path(relative_path)
        return nil unless File.exist?(output_path)

        File.mtime(output_path)
      end
      # File info - end

      # Read - start
      def read_text(relative_path)
        File.read(output_path(relative_path))
      end
      # Read - end

      # Write - start
      def write_csv(relative_path, csv)
        csv = Util::Validate.required_string("csv", csv)

        write_text_file(relative_path, csv, false)
      end

      def write_json(relative_path, json, pretty = true)
        json = Util::Validate.required_string("json", json)

        content = pretty ? pretty_json(json) : json

        write_text_file(relative_path, content, true)
      end
      # Write - end

      # File operations - start
      def delete_dir(relative_dir)
        relative_dir = Validate.required_string("relative_dir", relative_dir)
        if relative_dir.include?("..") || relative_dir.start_with?("/")
          raise ArgumentError, "relative_dir must be a safe relative path."
        end

        full_path = output_path(relative_dir)

        FileUtils.rm_rf(full_path)
      end
      # File operations - end

      private

      def pretty_json(json)
        JSON.pretty_generate(JSON.parse(json))
      rescue JSON::ParserError
        json
      end

      def write_text_file(relative_path, content, ensure_trailing_newline)
        output_path = output_path(relative_path)
        FileUtils.mkdir_p(File.dirname(output_path))

        content = content.to_s
        content += "\n" if ensure_trailing_newline && !content.end_with?("\n")

        File.write(output_path, content)
        output_path
      end
    end
  end
end
