# frozen_string_literal: true

module FileTypeRestrictions
  extend ActiveSupport::Concern

  def file_types_inherited?
    allowed_file_types.blank?
  end

  def selected_file_type_groups
    AllowedFileTypes.selected_groups_for(allowed_file_types)
  end
end
