# == Schema Information
#
# Table name: searchable_organizations
#
#  ein              :string           not null, primary key
#  name             :string           not null
#  ico              :string
#  street           :string
#  city             :string
#  state            :string
#  zip              :string
#  org_group        :string
#  subsection       :string
#  affiliation      :string
#  classification   :string
#  ruling           :string
#  deductibility    :string
#  foundation       :string
#  activity         :string
#  organization     :string
#  status           :string
#  tax_period       :string
#  asset_cd         :string
#  income_cd        :string
#  filing_req_cd    :string
#  pf_filing_req_cd :string
#  acct_pd          :string
#  asset_amt        :string
#  income_amt       :string
#  revenue_amt      :string
#  ntee_cd          :string
#  sort_name        :string
#

class SearchableOrganization < ApplicationRecord
  searchkick word_start: [:name], batch_size: 10_000

  def search_data
    {
      ein: ein,
      name: name
    }
  end
  
  self.primary_key = 'ein'

  def self.search_for(query, limit: 10)
    self.search(query, limit: limit, misspellings: { prefix_length: 2 }, match: :word_start)
  end
  
  def formatted_ein
    ein[0..1] + '-' + ein[2..8]
  end

  def formatted_name
    name.titleize
  end
end
