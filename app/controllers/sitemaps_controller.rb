class SitemapsController < ApplicationController
  def show
    @categories = Category.all
    @subforums = Subforum.all
    @threads = ForumThread.includes(:subforum).order(updated_at: :desc).limit(5000)
    @users = User.where(banned: false).order(updated_at: :desc).limit(2000)

    respond_to do |format|
      format.xml
    end
  end
end
