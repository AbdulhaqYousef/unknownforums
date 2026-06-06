# frozen_string_literal: true

module FileTypeRestrictions
  extend ActiveSupport::Concern

  def file_types_inherited?
    return true unless file_type_rules_supported?

    allowed_file_types.blank?
  end

  def selected_file_type_groups
    AllowedFileTypes.selected_groups_for(file_type_rules_supported? ? allowed_file_types : nil)
  end

  def custom_upload_types_text
    return "" unless file_type_rules_supported?

    AllowedFileTypes.custom_text_for(allowed_file_types)
  end

  private

  def file_type_rules_supported?
    self.class.column_names.include?("allowed_file_types")
  end
end
