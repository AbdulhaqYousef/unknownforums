# frozen_string_literal: true

module AdminFileTypeParams
  extend ActiveSupport::Concern

  private

  def apply_record_file_type_settings(record, inherit: true)
    if inherit && params[:file_type_inherit] == "1"
      record.allowed_file_types = nil
      return true
    end

    groups = Array(params[:file_type_groups]).compact_blank
    if groups.empty?
      record.errors.add(:base, "Select at least one file type group, or choose the inherit option.")
      return false
    end

    record.allowed_file_types = AllowedFileTypes.store_groups(groups)
    true
  end
end
