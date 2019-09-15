module Hooks
  class GetZapierWebhookByType < ApplicationQuery
    def initialize(relation = ZapierWebhook.all)
      @relation = relation
    end

    def call(partner:, hook_type:)
      @relation.find_by(partner: partner, hook_type: hook_type)
    end
  end
end
