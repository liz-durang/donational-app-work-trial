module Campaigns
  class UpdateCampaign < ApplicationCommand

    required do
      model :campaign
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
      campaign.update!(
        title: title,
        description: description,
        slug: slug,
        default_contribution_amounts: default_contribution_amounts
      )

      nil
    end

    private

    def slug_unique?
      Partners::GetCampaignBySlug.call(slug: slug).present? && campaign.slug != slug
    end
  end
end
