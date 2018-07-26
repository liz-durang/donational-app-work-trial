# == Schema Information
#
# Table name: partners
#
#  id                           :uuid             not null, primary key
#  name                         :string
#  website_url                  :string
#  description                  :text
#  platform_fee_percentage      :decimal(, )      default(0.0)
#  primary_branding_color       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donor_questions_schema       :jsonb
#  payment_processor_account_id :string
#

class Partner < ApplicationRecord
  has_many :campaigns
  has_many :managed_portfolios
  # Partner administrators
  has_and_belongs_to_many :donors
  has_one_attached :logo

  def donor_questions
    return if donor_questions_schema.nil?

    donor_questions_schema['questions'].map { |q| DonorQuestion.new(q) }
  end

  class DonorQuestion
    include ActiveModel::Model

    attr_reader :name, :title, :type, :options, :required

    def initialize(h)
      @name = h['name']
      @title = h['title']
      @type = h['type']
      @options = h['options']
      @required = h['required'] || false
    end
  end
end
