module Partners
  class GetChapterOptionsByPartnerOrCampaign < ApplicationQuery
    def initialize(relation = Partner.all)
      @relation = relation
    end

    def call(partner_id:, campaign_id:)
      return nil if partner_id.blank?

      # NOTE: Do not assume that the correct partner is that which the campaign belongs to.
      # The partner is determined by the user's choice of currency, not by the partner of the campaign which
      # onboarded the user.
      partner = @relation.find(partner_id)
      campaign = Partners::GetCampaignById.call(id: campaign_id)

      # Based on the partners relevant to the selected currency or to the campaign, retrieve the chapter options from the
      # donor_questions_schema column.
      all_chapters = [partner, campaign&.partner].compact.uniq.flat_map do |p|
        Partners::GetChapterOptionsByPartner.call(id: p.id)
      end&.sort

      # Fall back to using other partners' chapter options.
      all_chapters = all_chapters.presence || @relation.flat_map do |p|
                                                Partners::GetChapterOptionsByPartner.call(id: p.id)
                                              end&.sort

      # Find a chapter whose name includes the campaign's name (or vice versa); make this selected by default by putting
      # in first place.
      # E.g. the campaign with name 'Cambridge' should pre-select the option 'University of Cambridge'.
      # If not found, set the default as 'N/A' (which should otherwise be the second option.)
      list = ((['N/A'] + all_chapters).sort_by do |chapter|
        if name_match?(campaign, chapter)
          0
        elsif chapter == 'N/A'
          1
        else
          2
        end
      end + ['Other']).compact.uniq

      # Some donor_questions_schemas chapter lists include the option 'Other', which I'd like to rename
      list[list.index('Other')] = 'Other (please type in your chapter)'
      list
    end

    def name_match?(campaign, chapter)
      if campaign.blank?
        false
      else
        campaign.title.upcase.in?(chapter.upcase) || chapter.upcase.in?(campaign.title.upcase)
      end
    end
  end
end
