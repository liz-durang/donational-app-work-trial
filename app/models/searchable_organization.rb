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
end
