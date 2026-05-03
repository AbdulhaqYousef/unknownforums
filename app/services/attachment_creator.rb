require "securerandom"

class AttachmentCreator
  def self.attach(attachable:, user:, files:)
    Array(files).compact.select { |f| f.respond_to?(:original_filename) }.each do |file|
      content_type = file.content_type.presence || "application/octet-stream"
      stored_filename = stored_filename_for(attachable, file.original_filename)
      attachment = Attachment.new(
        attachable: attachable,
        user: user,
        filename: stored_filename,
        content_type: content_type,
        byte_size: file.size,
        is_video: content_type.start_with?("video/")
      )
      attach_file(attachment, file, attachable, user, content_type)
      if attachment.save
        VirusTotalScanJob.perform_later(attachment.id)
      end
    end
  end

  def self.attach_file(attachment, file, attachable, user, content_type)
    io = file.respond_to?(:tempfile) ? file.tempfile : file.to_io
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
