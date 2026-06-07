class SiteSetting < ApplicationRecord
  MAINTENANCE_KEY = "maintenance_mode".freeze
  MAINTENANCE_MESSAGE_KEY = "maintenance_message".freeze
  ALLOWED_FILE_TYPES_KEY = "allowed_file_types".freeze
  MAX_UPLOAD_BYTES_KEY = "max_upload_bytes".freeze

  validates :key, presence: true, uniqueness: true

  def self.get(key)
    Rails.cache.fetch("site_setting:#{key}", expires_in: 1.minute) do
      find_by(key: key)&.value
    end
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value.to_s
    record.save!
    Rails.cache.delete("site_setting:#{key}")
  end

  def self.maintenance_mode?
    get(MAINTENANCE_KEY) == "true"
  end

  def self.maintenance_message
    get(MAINTENANCE_MESSAGE_KEY).presence || "The site is undergoing maintenance. We'll be back shortly."
  end

  def self.allowed_file_type_groups_raw
    get(ALLOWED_FILE_TYPES_KEY)
  end

  def self.selected_file_type_groups
    AllowedFileTypes.selected_groups_for(allowed_file_type_groups_raw)
  end

  def self.set_allowed_file_type_groups(group_keys, custom: nil)
    value = AllowedFileTypes.store_policy(groups: group_keys, custom: custom) || ""
    set(ALLOWED_FILE_TYPES_KEY, value)
  end

  def self.custom_upload_types_text
    AllowedFileTypes.custom_text_for(allowed_file_type_groups_raw)
  end

  def self.upload_max_gb_input
    UploadLimits.gb_input_value(UploadLimits.global_max_bytes)
  end

  def self.set_upload_max_gb!(value)
    bytes = UploadLimits.parse_gb_param(value)
    raise ArgumentError, "Invalid upload size" unless bytes

    UploadLimits.set_global_max_bytes!(bytes)
  end
end
