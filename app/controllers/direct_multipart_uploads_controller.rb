# frozen_string_literal: true

class DirectMultipartUploadsController < ApplicationController
  before_action :require_login

  def create
    result = R2MultipartUpload.begin_upload(
      filename: params.require(:filename),
      content_type: params[:content_type],
      byte_size: params.require(:byte_size).to_i,
      max_bytes: upload_limit_bytes
    )
    render json: result
  rescue R2MultipartUpload::UploadError, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def presign_part
    result = R2MultipartUpload.presign_part(
      key: params.require(:key),
      upload_id: params.require(:upload_id),
      part_number: params.require(:part_number)
    )
    render json: result
  rescue R2MultipartUpload::UploadError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def complete
    signed_id = R2MultipartUpload.complete_upload(
      blob_id: params.require(:blob_id),
      upload_id: params.require(:upload_id),
      key: params.require(:key),
      parts: params.require(:parts)
    )
    render json: { signed_id: signed_id }
  rescue R2MultipartUpload::UploadError, ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def abort
    R2MultipartUpload.abort_upload(
      key: params.require(:key),
      upload_id: params.require(:upload_id)
    )
    head :no_content
  rescue R2MultipartUpload::UploadError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def upload_limit_bytes
    subforum = Subforum.find_by(id: params[:subforum_id])
    if subforum
      UploadLimits.max_bytes_for_subforum(subforum, user: current_user)
    else
      LevelPerks.max_upload_bytes_for(current_user)
    end
  end
end
