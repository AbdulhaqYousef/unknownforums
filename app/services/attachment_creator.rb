class AttachmentCreator
  def self.attach(attachable:, user:, files:)
    Array(files).compact.select { |f| f.respond_to?(:original_filename) }.each do |file|
      content_type = file.content_type.presence || "application/octet-stream"
      attachment = Attachment.new(
        attachable: attachable,
        user: user,
        filename: file.original_filename,
        content_type: content_type,
        byte_size: file.size,
        is_video: content_type.start_with?("video/")
      )
      attachment.file.attach(file)
      attachment.save
    end
  end
end
