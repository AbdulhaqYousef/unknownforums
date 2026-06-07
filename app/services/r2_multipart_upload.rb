# frozen_string_literal: true

require "aws-sdk-s3"

class R2MultipartUpload
  PART_SIZE = 100.megabytes
  MAX_PARTS = 10_000

  class UploadError < StandardError; end

  class << self
    def begin_upload(filename:, content_type:, byte_size:, max_bytes: nil)
      raise UploadError, "Multipart upload requires cloud storage" unless Attachment.multipart_enabled?
      limit = max_bytes || UploadLimits.global_max_bytes
      raise UploadError, "File is too large — maximum upload size is #{UploadLimits.label_for(limit)}" if byte_size > limit
      raise UploadError, "File is empty" if byte_size <= 0

      part_size = part_size_for(byte_size)
      blob = ActiveStorage::Blob.create_before_direct_upload!(
        filename: filename,
        byte_size: byte_size,
        checksum: placeholder_checksum(byte_size),
        content_type: content_type.presence || "application/octet-stream",
        service_name: Rails.application.config.active_storage.service
      )

      response = client.create_multipart_upload(
        bucket: bucket,
        key: blob.key,
        content_type: blob.content_type
      )

      blob.update!(metadata: (blob.metadata || {}).merge(
        "multipart" => true,
        "multipart_upload_id" => response.upload_id
      ))

      {
        blob_id: blob.id,
        upload_id: response.upload_id,
        key: blob.key,
        part_size: part_size,
        part_count: part_count_for(byte_size, part_size)
      }
    end

    def presign_part(key:, upload_id:, part_number:)
      part_number = part_number.to_i
      raise UploadError, "Invalid part number" unless part_number.between?(1, MAX_PARTS)

      url = presigner.presigned_url(
        :upload_part,
        bucket: bucket,
        key: key,
        upload_id: upload_id,
        part_number: part_number,
        expires_in: 24.hours.to_i
      )

      { url: url }
    end

    def complete_upload(blob_id:, upload_id:, key:, parts:)
      blob = ActiveStorage::Blob.find(blob_id)
      stored_upload_id = blob.metadata&.fetch("multipart_upload_id", nil).to_s
      raise UploadError, "Upload session not found" if stored_upload_id.blank? || stored_upload_id != upload_id.to_s
      raise UploadError, "Storage key mismatch" if blob.key != key.to_s

      sorted_parts = Array(parts).map do |part|
        {
          part_number: part["part_number"].to_i,
          etag: part["etag"].to_s.delete('"')
        }
      end.sort_by { |part| part[:part_number] }

      raise UploadError, "No upload parts received" if sorted_parts.empty?

      result = client.complete_multipart_upload(
        bucket: bucket,
        key: key,
        upload_id: upload_id,
        multipart_upload: { parts: sorted_parts }
      )

      etag = result.etag.to_s.delete('"')
      blob.update!(
        checksum: checksum_for_etag(etag),
        metadata: (blob.metadata || {}).except("multipart_upload_id").merge(
          "multipart" => true,
          "multipart_complete" => true
        )
      )

      blob.signed_id
    end

    def abort_upload(key:, upload_id:)
      client.abort_multipart_upload(bucket: bucket, key: key, upload_id: upload_id)
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.warn("R2MultipartUpload abort failed: #{e.class}: #{e.message}")
      nil
    end

    private

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: ENV.fetch("R2_ACCESS_KEY_ID"),
        secret_access_key: ENV.fetch("R2_SECRET_ACCESS_KEY"),
        region: "auto",
        endpoint: ENV.fetch("R2_ENDPOINT"),
        force_path_style: true
      )
    end

    def presigner
      @presigner ||= Aws::S3::Presigner.new(client: client)
    end

    def bucket
      ENV.fetch("R2_BUCKET")
    end

    def part_size_for(byte_size)
      size = PART_SIZE
      parts = part_count_for(byte_size, size)
      return size if parts <= MAX_PARTS

      size = (byte_size.to_f / MAX_PARTS).ceil
      [ size, 5.megabytes ].max
    end

    def part_count_for(byte_size, part_size)
      (byte_size.to_f / part_size).ceil
    end

    def placeholder_checksum(byte_size)
      Base64.strict_encode64(Digest::MD5.digest("multipart-pending:#{byte_size}:#{SecureRandom.uuid}"))
    end

    def checksum_for_etag(etag)
      Base64.strict_encode64(Digest::MD5.digest("multipart-complete:#{etag}"))
    end
  end
end
