# frozen_string_literal: true

require 'csv'

namespace :donor do
  desc 'Delete donors from file accounts_to_delete.csv'
  task delete: :environment do
    csv_path = Rails.root.join('lib/assets/accounts_to_delete.csv')
    csv = CSV.read(csv_path, headers: true)

    csv.each do |row|
      puts "Deleting donor #{row['Donor ID']}"
      donor = Donor.find_by(id: row['Donor ID'])
      next unless donor

      _selected_porfolios = SelectedPortfolio.where(donor:).destroy_all
      donor.partners = []
      donor.destroy
      puts "Deleted donor #{row['Donor ID']}"
    end
  end

  desc 'Find children count for a donor'
  task find_children: :environment do
    csv_path = Rails.root.join('lib/assets/accounts_to_delete.csv')
    csv = CSV.read(csv_path, headers: true)

    hash = Hash.new(0)
    csv.each do |row|
      donor = Donor.find_by(id: row['Donor ID'])
      next unless donor

      hash[:selected_portfolios] += SelectedPortfolio.where(donor:).count
      hash[:portfolios] += donor.portfolios.count
      hash[:payment_methods] += donor.payment_methods.count
      hash[:partner_affiliations] += donor.partner_affiliations.count
      hash[:subscriptions] += donor.subscriptions.count
      hash[:contributions] += donor.contributions.count
      hash[:donations] += donor.contributions.map { |u| u.donations.count }.sum
    end

    hash.each do |key, value|
      puts "#{key}: #{value}"
    end
  end
end
