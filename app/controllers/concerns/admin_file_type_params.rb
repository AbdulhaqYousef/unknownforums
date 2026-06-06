# frozen_string_literal: true

module AdminFileTypeParams
  extend ActiveSupport::Concern

  private

  def apply_record_file_type_settings(record, inherit: true)
    custom = params[:custom_upload_types]

    if inherit && params[:file_type_inherit] == "1"
      record.allowed_file_types = AllowedFileTypes.store_inherit_custom(custom: custom)
      return true
    end

    groups = Array(params[:file_type_groups]).compact_blank
    if groups.empty? && custom.to_s.strip.blank?
      record.errors.add(:base, "Select at least one file type group, add custom extensions, or use the inherit option.")
      return false
    end

    record.allowed_file_types = AllowedFileTypes.store_policy(groups: groups, custom: custom)
    true
  end
end
