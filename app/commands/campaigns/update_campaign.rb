module Campaigns
  class UpdateCampaign < ApplicationCommand

    required do
      model :campaign
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
      campaign.update!(
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
      return false if campaign.slug == normalized_slug

      Partners::GetCampaignBySlug.call(slug: normalized_slug).present?
    end

    def normalized_slug
      slug.parameterize
    end
  end
end
