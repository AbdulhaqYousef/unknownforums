class Admin::ThreadsController < ApplicationController
  before_action :require_admin
  before_action :set_subforum

  def index
    @threads   = @subforum.forum_threads.includes(:user).order(pinned: :desc, created_at: :desc).page(params[:page])
    @subforums = Subforum.order(:name)
  end

  private

  def set_subforum
    @subforum = Subforum.find(params[:subforum_id])
  end
end
