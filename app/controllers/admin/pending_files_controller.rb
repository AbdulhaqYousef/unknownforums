# frozen_string_literal: true

class Admin::PendingFilesController < ApplicationController
  before_action :require_moderator

  def index
    @attachments = Attachment.pending_approval
                             .includes(:user, file_attachment: :blob)
                             .order(created_at: :desc)
                             .page(params[:page])
                             .per(30)
  end
end
