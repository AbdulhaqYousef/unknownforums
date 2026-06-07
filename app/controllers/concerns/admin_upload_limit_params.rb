# frozen_string_literal: true

module AdminUploadLimitParams
  extend ActiveSupport::Concern

  private

  def apply_record_upload_limit_settings(record, inherit: true)
    unless record.class.column_names.include?("max_upload_bytes")
      return true
    end

    if inherit && params[:upload_limit_inherit] == "1"
      record.max_upload_bytes = nil
      return true
    end

    bytes = UploadLimits.parse_gb_param(params[:upload_max_gb])
    if bytes.nil?
      record.errors.add(:base, "Enter a valid upload size limit in GB.")
      return false
    end

    record.max_upload_bytes = bytes
    true
  end
end
