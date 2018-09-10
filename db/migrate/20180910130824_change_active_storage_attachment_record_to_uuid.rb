class ChangeActiveStorageAttachmentRecordToUuid < ActiveRecord::Migration[5.2]
  def change
    change_column :active_storage_attachments, :record_id, 'uuid using gen_random_uuid()', null: false, unique: true
  end
end
