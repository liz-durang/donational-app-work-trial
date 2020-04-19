# frozen_string_literal: true

class GrantsController < ApplicationController
  def show
    @grant = grant_by_short_id

    @donations = @grant.donations.includes(contribution: %i[partner donor])
  end

  private

  def grant_by_short_id
    lower_uuid = "#{params[:short_id]}00-0000-0000-0000-000000000000"
    upper_uuid = "#{params[:short_id]}ff-ffff-ffff-ffff-ffffffffffff"
    Grant.where(id: lower_uuid..upper_uuid).order(processed_at: :desc).first
  end
end
