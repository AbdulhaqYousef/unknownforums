require "securerandom"

class AttachmentCreator
  def self.attach(attachable:, user:, files:, signed_ids: nil)
    allowed_rules = AllowedFileTypes.rules_for_attachable(attachable)
    allowed_types = allowed_rules[:types]
    if signed_ids.present?
      attach_from_signed_ids(attachable: attachable, user: user, signed_ids: signed_ids, allowed_rules: allowed_rules)
    else
      attach_from_uploads(attachable: attachable, user: user, files: files, allowed_rules: allowed_rules)
    end
  end

  def self.attach_from_signed_ids(attachable:, user:, signed_ids:, allowed_rules:)
    allowed_types = allowed_rules[:types]
    errors = []
    Array(signed_ids).compact.each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      unless blob
        errors << "Invalid upload reference"
        next
      end
      label = blob.filename.to_s

      if blob.byte_size > Attachment::MAX_SIZE
        errors << "#{label}: file is too large — maximum upload size is #{Attachment.max_size_label}"
        blob.purge_later
        next
      end

      content_type = blob.content_type.presence || "application/octet-stream"
      unless AllowedFileTypes.type_allowed?(content_type, label, allowed_rules)
        errors << "#{label}: content type is not allowed in this forum"
        blob.purge_later
        next
      end

      mime_ok = true
      blob.open do |io|
        unless MimeValidator.valid?(content_type, io)
          errors << "#{label}: file content does not match its declared type"
          blob.purge_later
          mime_ok = false
        end
      end
      next unless mime_ok

      stored_filename = stored_filename_for(attachable, label)
      attachment = Attachment.new(
        attachable: attachable,
        user: user,
        filename: stored_filename,
        content_type: content_type,
        byte_size: blob.byte_size,
        is_video: content_type.start_with?("video/"),
        allowed_content_types: allowed_types
      )
      attachment.file.attach(blob)
      finalize_attachment(attachment, label, errors)
    end
    errors
  end

  def self.attach_from_uploads(attachable:, user:, files:, allowed_rules:)
    allowed_types = allowed_rules[:types]
    errors = []
    Array(files).compact.select { |f| f.respond_to?(:original_filename) }.each do |file|
      content_type = file.content_type.presence || "application/octet-stream"

      unless AllowedFileTypes.type_allowed?(content_type, file.original_filename, allowed_rules)
        errors << "#{file.original_filename}: content type is not allowed in this forum"
        next
      end

      io = file.respond_to?(:tempfile) ? file.tempfile : file.to_io
      io.rewind if io.respond_to?(:rewind)
      unless MimeValidator.valid?(content_type, io)
        errors << "#{file.original_filename}: file content does not match its declared type"
        next
      end
      io.rewind if io.respond_to?(:rewind)

      stored_filename = stored_filename_for(attachable, file.original_filename)
      attachment = Attachment.new(
        attachable: attachable,
        user: user,
        filename: stored_filename,
        content_type: content_type,
        byte_size: file.size,
        is_video: content_type.start_with?("video/"),
        allowed_content_types: allowed_types
      )
      attach_file(attachment, io, attachable, user, content_type)
      finalize_attachment(attachment, file.original_filename, errors)
    end
    errors
  end

  def self.finalize_attachment(attachment, label, errors)
    if attachment.save
      if attachment.vt_scannable?
        VirusTotalScanJob.perform_later(attachment.id)
      else
        attachment.update_columns(vt_status: "skipped", approved: true)
      end
    else
      attachment.file.purge if attachment.file.attached?
      errors << "#{label}: #{attachment.errors.full_messages.join(', ')}"
    end
  end

  def self.attach_file(attachment, io, attachable, user, content_type)
    io.rewind if io.respond_to?(:rewind)

    if attachable.is_a?(PrivateMessage)
      attachment.file.attach(
        io: io,
        filename: attachment.filename,
        content_type: content_type,
        key: dm_file_key(attachment.filename, attachable, user)
      )
    else
      attachment.file.attach(
        io: io,
        filename: attachment.filename,
        content_type: content_type
      )
    end
  end

  def self.stored_filename_for(attachable, filename)
    return filename unless forum_upload?(attachable)

    prefix = context_prefix_for(attachable)
    return filename if prefix.blank?

    extension = File.extname(filename.to_s)
    basename = File.basename(filename.to_s, extension)
    safe_basename = basename.gsub(/[^a-zA-Z0-9._-]/, "_").presence || "file"
    "[#{prefix}]#{safe_basename}[unknownforums]#{extension}"
  end

  def self.dm_file_key(filename, message, user)
    safe_filename = filename.to_s.gsub(/[^a-zA-Z0-9._-]/, "_")
    date_path = Time.current.utc.strftime("%Y/%m/%d")
    "dmfile/#{date_path}/user-#{user.id}/message-#{message.id}/#{SecureRandom.uuid}-#{safe_filename}"
  end

  def self.forum_upload?(attachable)
    attachable.is_a?(Post) || attachable.is_a?(ForumThread)
  end

  def self.context_prefix_for(attachable)
    source = forum_context_name(attachable)
    source.to_s.parameterize(separator: "").first(4).downcase
  end

  def self.forum_context_name(attachable)
    thread = attachable.is_a?(Post) ? attachable.thread : attachable
    thread&.subforum&.category&.name.presence || thread&.title
  end
end
