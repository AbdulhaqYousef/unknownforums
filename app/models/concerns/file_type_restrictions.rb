# frozen_string_literal: true

module FileTypeRestrictions
  extend ActiveSupport::Concern

  def file_types_inherited?
    return true unless file_type_rules_supported?
    return true if allowed_file_types.blank?

    AllowedFileTypes.inherit_groups_only?(allowed_file_types)
  end

  def selected_file_type_groups
    return SiteSetting.selected_file_type_groups if file_types_inherited?

    AllowedFileTypes.selected_groups_for(allowed_file_types)
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
