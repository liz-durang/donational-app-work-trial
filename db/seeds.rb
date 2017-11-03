# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

require 'open-uri'

csv_records = URI.parse('https://docs.google.com/spreadsheets/d/e/2PACX-1vQV9_PagLJt_DS5haB-E65owCl97TuCSsdvX2oVSE8WNkhLlw4mr46mpAxlmenNdPUwIrfs0LqZ9vQy/pub?gid=0&single=true&output=csv').read

require 'csv'

csv = CSV.parse(csv_records, :headers => true)

csv.each do |row|
  puts row['name']
  Organization
    .find_or_create_by(ein: row['name'].parameterize)
    .update(
      name: row['name'],
      description: row['description'],
      long_term_impact: row['research_policy_and_advocacy'],
      immediate_impact: row['service_delivery'],
      cause_area: row['cause_area']
    )
end
