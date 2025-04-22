# frozen_string_literal: true

namespace :csv do
  desc 'Convert Markdown table to CSV. Usage: rake csv:markdown_to_csv[file_path]'
  task :markdown_to_csv, [:file_path] => :environment do |_t, args|
    require 'csv'

    file_path = args[:file_path]

    if file_path.nil? || file_path.empty?
      puts 'Error: Please provide a file path. Usage: rake csv:markdown_to_csv[file_path]'
      next
    end

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      next
    end

    # Read the markdown file
    markdown_content = File.read(file_path)

    # Extract headers and rows from markdown table
    lines = markdown_content.split("\n").reject(&:empty?)

    # Skip if there aren't enough lines for a table
    if lines.size < 2
      puts "Error: The file doesn't appear to contain a markdown table"
      next
    end

    # Extract headers from the first line
    headers = lines[0].split('|').map(&:strip).reject(&:empty?)

    # Skip the separator line (line with dashes)
    rows = []
    lines[2..-1].each do |line|
      # Extract values from each row
      values = line.split('|').map(&:strip).reject(&:empty?)
      rows << values if values.any?
    end

    # Create the output CSV file path (same location as input file)
    output_path = file_path.sub(/\.[^.]+\z/, '.csv')

    # Write to CSV
    CSV.open(output_path, 'w') do |csv|
      csv << headers
      rows.each do |row|
        csv << row
      end
    end

    puts "Successfully converted markdown table to CSV: #{output_path}"
  end
end
