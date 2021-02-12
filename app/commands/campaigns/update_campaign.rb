module Campaigns
  class UpdateCampaign < ApplicationCommand

    required do
      model :campaign
      string :title
      string :description
      string :slug
      array :default_contribution_amounts
      integer :minimum_contribution_amount
      boolean :allow_one_time_contributions
    end

    optional do
      string :banner_image
      string :contribution_amount_help_text
    end

    def validate
      ensure_slug_not_used!
      ensure_default_contribution_amounts_greater_than_minimum!
    end

    def execute
      campaign.update!(
        slug: normalized_slug,
        title: title,
        description: description,
        contribution_amount_help_text: contribution_amount_help_text || '',
        default_contribution_amounts: default_contribution_amounts,
        minimum_contribution_amount: minimum_contribution_amount,
        allow_one_time_contributions: allow_one_time_contributions
      )

      campaign.banner_image.attach(banner_image) if banner_image.present?

      nil
    end

    private

    # Validations
    def ensure_slug_not_used!
      return unless slug_already_used?

      add_error(:campaign, :slug_already_used, 'The slug has already been taken')
    end

    def ensure_default_contribution_amounts_greater_than_minimum!
      return if default_contribution_amounts.min >= minimum_contribution_amount

      add_error(:campaign, :default_contribution_amounts, 'Default contribution amounts must be greater than minimum contribution amount')
    end

    def slug_already_used?
      return false if campaign.slug == normalized_slug

      Partners::GetCampaignBySlug.call(slug: normalized_slug).present?
    end

    def normalized_slug
      slug.parameterize
    end
  end
end
