module Campaigns
  class CreateCampaign < ApplicationCommand

    required do
      model :partner
      string :title
      string :description
      string :slug
      array :default_contribution_amounts
    end

    def validate
      return unless slug_unique?

      add_error(:campaign, :slug_already_used, 'The slug has already been taken')
    end

    def execute
      Campaign.create!(
        partner: partner,
        title: title,
        description: description,
        slug: slug,
        default_contribution_amounts: default_contribution_amounts
      )

      nil
    end

    private

    def slug_unique?
      Partners::GetCampaignBySlug.call(slug: slug).present?
    end
  end
end
