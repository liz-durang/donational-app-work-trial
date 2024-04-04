module Campaigns
  class CreateCampaign < ApplicationCommand
    required do
      model :partner
      string :slug
      integer :minimum_contribution_amount
    end

    optional do
      string :banner_image
      string :description
      string :title
      string :contribution_amount_help_text
      array :default_contribution_amounts
      boolean :allow_one_time_contributions
    end

    def validate
      ensure_slug_not_used!
      ensure_default_contribution_amounts_greater_than_minimum!
      ensure_required_fields_present!
    end

    def execute
      campaign = Campaign.create!(
        slug: normalized_slug,
        partner:,
        title: title || 'New Campaign',
        description:,
        contribution_amount_help_text:,
        default_contribution_amounts:,
        minimum_contribution_amount:,
        allow_one_time_contributions: allow_one_time_contributions || false
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
      return if default_contribution_amounts.blank?
      return if default_contribution_amounts.min >= minimum_contribution_amount

      add_error(:campaign, :default_contribution_amounts,
                'Default contribution amounts must be greater than minimum contribution amount')
    end

    def ensure_required_fields_present!
      return if partner.uses_one_for_the_world_checkout?

      add_error(:campaign, :default_contribution_amounts, :blank) if default_contribution_amounts.blank?
      add_error(:campaign, :allow_one_time_contributions, :blank) unless allow_one_time_contributions.in?([false, true])
    end

    def slug_already_used?
      Partners::GetCampaignBySlug.call(slug:).present?
    end

    def normalized_slug
      slug.parameterize
    end
  end
end
