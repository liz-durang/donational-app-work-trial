module Partners
  class GetChapterOptionsByPartner < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      partner = @relation.find(id)

      partner&.donor_questions_schema.try(:dig, 'questions')&.select do |q|
        q.try(:dig, 'name') == 'chapter'
      end&.first.try(:dig, 'options')
    end
  end
end
