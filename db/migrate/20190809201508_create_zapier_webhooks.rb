class CreateZapierWebhooks < ActiveRecord::Migration[5.2]
  def change
    create_table :zapier_webhooks, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :hook_url
      t.string :hook_type
      t.references :partner, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
