module Hooks
  class CreateOrUpdateWebhook < ApplicationCommand
    required do
      string :hook_url
      string :hook_type
      string :partner_id

    end

    def execute
      ZapierWebhook.find_or_create_by!(partner_id: partner_id, hook_type: hook_type).tap do |webhook|
        webhook.hook_url = hook_url
        webhook.save!
      end
    end
  end
end
