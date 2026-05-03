class AddVirustotalToAttachments < ActiveRecord::Migration[8.1]
  def change
    add_column :attachments, :vt_status,   :string,  default: "pending"
    add_column :attachments, :vt_scan_id,  :string
    add_column :attachments, :vt_report,   :jsonb,   default: {}
    add_column :attachments, :vt_scanned_at, :datetime
    add_index  :attachments, :vt_status
  end
end
