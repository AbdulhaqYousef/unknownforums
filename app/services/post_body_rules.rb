# frozen_string_literal: true

class PostBodyRules
  def self.files_in_request?(files: nil, signed_ids: nil)
    Array(signed_ids).any?(&:present?) || uploaded_files?(files)
  end

  def self.allow_empty?(post:, files: nil, signed_ids: nil)
    return false if post.body.to_s.strip.present?

    post.attachments.any? || files_in_request?(files: files, signed_ids: signed_ids)
  end

  def self.uploaded_files?(files)
    return false if files.blank?

    Array(files).any? do |file|
      file.respond_to?(:size) ? file.size.to_i.positive? : file.present?
    end
  end
  private_class_method :uploaded_files?
end
