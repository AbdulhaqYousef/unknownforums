# frozen_string_literal: true

module UploadSizeRestrictions
  extend ActiveSupport::Concern

  def upload_limit_inherited?
    return true unless upload_limit_supported?

    max_upload_bytes.blank?
  end

  def upload_limit_gb_input
    return "" unless upload_limit_supported? && max_upload_bytes.present?

    UploadLimits.gb_input_value(max_upload_bytes)
  end

  def effective_upload_limit_label
    case self
    when Category
      UploadLimits.label_for(UploadLimits.max_bytes_for_category(self))
    when Subforum
      UploadLimits.label_for(UploadLimits.max_bytes_for_subforum(self))
    else
      UploadLimits.global_label
    end
  end

  private

  def upload_limit_supported?
    self.class.column_names.include?("max_upload_bytes")
  end
end
