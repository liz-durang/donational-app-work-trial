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
#  tsv              :tsvector
#

class SearchableOrganization < ApplicationRecord
  include PgSearch

  self.primary_key = 'ein'

  pg_search_scope :search_for,
    against: :name,
    using: {
      tsearch: {
        prefix: true,
        dictionary: 'english',
        tsvector_column: 'tsv'
      }
    }
  
  def formatted_ein
    ein[0..1] + '-' + ein[2..8]
  end
  
  def formatted_name
    name.titleize
  end
end
