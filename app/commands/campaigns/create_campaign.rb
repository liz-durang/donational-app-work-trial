module Campaigns
  class CreateCampaign < ApplicationCommand

    required do
      model :partner
      string :title
      string :description
      string :slug
      array :default_contribution_amounts
    end

    optional do
      string :banner_image
    end

    def validate
      return unless slug_already_used?

      add_error(:campaign, :slug_already_used, 'The slug has already been taken')
    end

    def execute
      campaign = Campaign.create!(
        partner: partner,
        title: title,
        description: description,
        slug: normalized_slug,
        default_contribution_amounts: default_contribution_amounts,
      )
      campaign.banner_image.attach(banner_image) if banner_image.present?

      nil
    end

    private

    def slug_already_used?
      Partners::GetCampaignBySlug.call(slug: slug).present?
    end

    def normalized_slug
      slug.parameterize
    end
  end
end
