module Campaigns
  class CreateCampaign < ApplicationCommand

    required do
      model :partner
      string :slug
      array :default_contribution_amounts
    end

    optional do
      string :banner_image
      string :description
      string :title
      string :contribution_amount_help_text
      boolean :allow_one_time_contributions
    end

    def validate
      return unless slug_already_used?

      add_error(:campaign, :slug_already_used, 'The slug has already been taken')
    end

    def execute
      campaign = Campaign.create!(
        slug: normalized_slug,
        partner: partner,
        title: title || 'New Campaign',
        description: description,
        contribution_amount_help_text: contribution_amount_help_text,
        default_contribution_amounts: default_contribution_amounts,
        allow_one_time_contributions: allow_one_time_contributions
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
