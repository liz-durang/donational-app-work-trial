# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

require 'open-uri'

csv_records = URI.parse('https://docs.google.com/spreadsheets/d/e/2PACX-1vQV9_PagLJt_DS5haB-E65owCl97TuCSsdvX2oVSE8WNkhLlw4mr46mpAxlmenNdPUwIrfs0LqZ9vQy/pub?gid=459179158&single=true&output=csv').read

require 'csv'

csv = CSV.parse(csv_records, :headers => true)

csv.each do |row|
  puts row['name']
  Organization
    .find_or_create_by(ein: row['ein'])
    .update(
      ein: row['ein'],
      name: row['name'],
      cause_area: row['cause_area'],
      description: row['description'],
      why_you_should_care: row['why_you_should_care'],
      mission: row['mission'],
      context: row['context'],
      impact: row['impact'],
      website_url: row['website_url'],
      annual_report_url: row['annual_report_url'],
      financials_url: row['financials_url'],
      form_990_url: row['form_990_url'],
      recommended_by: {
        give_well: row['recommended_by_givewell'],
        lycs: row['recommended_by_lycs'],
        agora: row['recommended_by_agora'],
        gates_foundation: row['recommended_by_gates_foundation'],
        animal_charity_evaluators: row['recomended_by_animal_charity_evaluators']
      }.select { |_,v| v == "TRUE" }.keys
    )
end
